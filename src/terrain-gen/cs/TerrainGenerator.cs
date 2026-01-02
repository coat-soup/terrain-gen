using System;
using System.Linq;
using Godot;
using Godot.Collections;
using System.Collections.Generic;

[GlobalClass]
public partial class TerrainGenerator : Node
{
    [Signal]
    public delegate void TerrainChunkFinishedLoadingEventHandler(TerrainChunk chunk);
    
    [Export] public float planetRadius { get; set; } = 12000.0f;
    [Export] public float terrainHeight { get; set; } = 1000.0f;
    [Export] public int chunkSize { get; set; } = 32;
    [Export] public float renderDist { get; set; } = 100.0f;

    [Export] public Material terrainMaterial;
    
    public Array<Array<int>> neighbours;
    public Vector3[] positions;
    public float[] heights;
    public Vector3[] windDirs;
    public float[] precipitations;
    public int[] climateZoneIDs;
    
    public OctreeNode tree;
    private int n_nodes;
    private int n_small_leaves;
    private int n_loaded_chunks;

    [Export] public FastNoiseLite noise;
    [Export] public float noiseScale = 0.4f;
    
    [Export] public Node3D camera;
    private Vector3I cameraChunkPos;
    
    public const float HALFSQRT3 = 0.86602540378f; // Sqrt(3)/2

    private Queue<OctreeNode> chunkLoadQueue = new Queue<OctreeNode>();
    private bool pauseChunkQueue;
    private GodotThread chunkThread;

    [Export] public bool regenAroundCamera = true;

    private double time;
    public Rid worldScenario;

    [Export] public FoliageGenerator fgen;
    
    
    public override void _Ready()
    {
        terrainMaterial.Set("shader_parameter/planet_radius", planetRadius);
        terrainMaterial.Set("shader_parameter/terrain_height", terrainHeight);

        worldScenario = GetTree().Root.GetWorld3D().Scenario;
        
        chunkThread = new GodotThread();
        chunkThread.Start(new Callable(this, MethodName.RunChunkQueue));
        
    }

    
    public void CreateTreeFromDataArrays(Array<Array<int>> _neighbours, Vector3[] _positions, float[] _heights, Vector3[] _windDirs, float[] _precipitations, int[] _climateZoneIDs)
    {
        neighbours = _neighbours;
        positions = _positions;
        heights = _heights;
        windDirs = _windDirs;
        precipitations = _precipitations;
        climateZoneIDs = _climateZoneIDs;
        GD.Print("Creating tree from data. Got heights size " + _heights.Length);

        tree = CreateRootNode(chunkSize);

        double time = Time.GetUnixTimeFromSystem();
        
        GD.Print("Root node size: ", tree.size);
        n_nodes = 0;
        n_small_leaves = 0;
        BuildTree(tree);
        GD.Print("Tree finished with " + n_nodes + " nodes (" + n_small_leaves + " size 0 leaves) in " + (Time.GetUnixTimeFromSystem() - time) + " seconds.");
    }


    public OctreeNode CreateRootNode(int cSize)
    {
        float margin = terrainHeight * 1.2f;
        float diameter = 2.0f * planetRadius + 2.0f * margin;
        float s = cSize;
        int si = 0;
        while (s < diameter) { s *= 2.0f; si += 1;}
        Vector3 rootPos = -Vector3.One * s / 2.0f;
        return new OctreeNode(rootPos, s, 0, si, 0);
    }
    
    
    public void LoadChunksAroundCamera()
    {
        time = Time.GetUnixTimeFromSystem();

        n_loaded_chunks = 0;
        
        //LoadChunks(tree, camera.Position);
        pauseChunkQueue = true;
        chunkLoadQueue.Clear();
        BuildTree(tree);
        pauseChunkQueue = false;
    }
    
    
    public void BuildTree(OctreeNode node)
    {
        n_nodes++;
        if (node.size == 0) n_small_leaves++;
        
        node.cell_id = CellIDFromNormal(node.position + Vector3.One * node.sideLength / 2.0f, node.cell_id);
        
        bool inRange = (node.position + Vector3.One * node.sideLength/2.0f).DistanceTo(camera.GlobalPosition) <= renderDist + node.sideLength * HALFSQRT3;
        
        // WARNING: the LOD-based subdivision alone (see range, above) might make the SDF check obsolete (but keep an eye on performance), and won't have the fake SDF issues.
        if (node.size > 0 && inRange && (node.depth == 0 || Mathf.Abs(SampleSDF(node.position + Vector3.One * node.sideLength/2.0f, node.cell_id)) <= node.sideLength * HALFSQRT3)) // SHOULD SUBDIVIDE
        {
            node.chunkQueued = false;
            
            if (node.children == null)
            {
                Vector3[] childPositions = [new Vector3(0,0,0), new Vector3(0,0,1), new Vector3(0,1,0), new Vector3(0,1,1), new Vector3(1,0,0), new Vector3(1,0,1), new Vector3(1,1,0), new Vector3(1,1,1)];
                node.children = new OctreeNode[8];
                for(int i = 0; i < 8; i++)
                {
                    node.children[i] = new OctreeNode(node.position + node.sideLength * childPositions[i] / 2.0f, node.sideLength / 2.0f, node.depth + 1, node.size - 1, node.cell_id, node.path + i.ToString(), node);
                }
            }
            for(int i = 0; i < node.children.Length; i++) BuildTree(node.children[i]);
        }
        else
        {
            n_loaded_chunks++;
            node.chunkQueued = true;
        }
    }

    public void CollapseNode(OctreeNode node)
    {
        if (node.chunk != null)
        {
            node.chunk.Unload();
            node.chunk = null;
            node.chunkQueued = false;
        }

        if (node.children != null) foreach (OctreeNode child in node.children)
        {
            CollapseNode(child);
        }

        node.children = null;
    }
    
    
    public float SampleSDF(Vector3 position, int cell = -1)
    {
        //return planetRadius - position.Length();
        
        if (cell == -1) cell = CellIDFromNormal(position.Normalized());
        return ProjectToSurface(position, cell).Length() - position.Length();
        //return planetRadius + terrainHeight * heights[cell] - position.Length();
    }
    
    
    public int CellIDFromNormal(Vector3 normal, int startCell = 0)
    {
        int id = startCell;
        float bestDot = normal.Dot(positions[startCell]);
		    
        while (true)
        {
            bool improved = false;
		    
            foreach (int nID in neighbours[id])
            {
                float d = normal.Dot(positions[nID]);
				    
                if (d > bestDot)
                {
                    bestDot = d;
                    id = nID;
                    improved = true;
                    break;
                }
            }
			    
            if (!improved)
                return id;
        }
    }


    public void RunChunkQueue()
    {
        while (true)
        {
            if (pauseChunkQueue) continue;
            BuildNodeChunks(tree);
            pauseChunkQueue = true;
        }
    }


    public void BuildNodeChunks(OctreeNode node)
    {
        if (pauseChunkQueue) return;
        
        if (node.chunk == null && node.chunkQueued)
        {
            node.chunk = new TerrainChunk(node.position, chunkSize, this, node.cell_id, (int)Mathf.Pow(2, node.size), node.path);
            if(node.chunk != null)
                Callable.From(() => { AddChild(node.chunk); }).CallDeferred();
            node.chunk.Load();
            node.chunk.Position = node.position;
            
            if (node.children != null)
            {
                foreach (OctreeNode child in node.children) CollapseNode(child);
                node.children = null;
            }
        }
        
        if (node.children != null && !node.chunkQueued) foreach (OctreeNode child in node.children) BuildNodeChunks(child);
        
        if (node.chunk != null && !node.chunkQueued)
        {
            node.chunk.Unload();
            node.chunkQueued = false;
            node.chunk = null;
        }
        
        if(node.depth == 0 && time > 0)
        {
            GD.Print("Loaded " + n_loaded_chunks + " chunks in " + (Time.GetUnixTimeFromSystem() - time) + " seconds.");
            time = 0;
        }
    }
    
    
    public float CalculateDensity(Vector3 position, int startingCell, bool refineCell = true)
    {
        int cell = refineCell? CellIDFromNormal(position.Normalized(), startingCell) : startingCell;

        float simHeight = InterpolateHeightBarycentric(position, cell);
        float height = planetRadius + (simHeight + (noise.GetNoise3Dv(position) -0.5f) * noiseScale) * terrainHeight;
        return height - position.Length();
    }
    
    
    public static bool IsPointInSphericalTriangle( Vector3 p,  Vector3 a,  Vector3 b,  Vector3 c){
        Vector3 ab = a.Cross(b);
        Vector3 bc = b.Cross(c);
        Vector3 ca = c.Cross(a);
            
        float s1 = ab.Dot(p);
        float s2 = bc.Dot(p);
        float s3 = ca.Dot(p);

        return (s1 >= 0.0 && s2 >= 0.0 && s3 >= 0.0) || (s1 <= 0.0 && s2 <= 0.0 && s3 <= 0.0);
    }
    
    
    public int[] FindDelaunayTriangle(int closest, Vector3 p)
    {
        Vector3 center = positions[closest];
        Godot.Collections.Array<int> _neighbours = neighbours[closest];

        for(int i = 0; i < _neighbours.Count; i++)
        {
            Vector3 b = positions[_neighbours[i]];
            Vector3 c = positions[_neighbours[(i + 1) % _neighbours.Count]];

            if (IsPointInSphericalTriangle(p, center, b, c))
                return [closest, _neighbours[i], _neighbours[(i + 1) % _neighbours.Count]];
        }

        return [closest, _neighbours[0], _neighbours[1]];
    }

    public static float TriArea(Vector3 a, Vector3 b, Vector3 c)
    {
        return Mathf.Atan2(
            a.Dot(b.Cross(c)),
            1.0f + a.Dot(b) + b.Dot(c) + c.Dot(a)
        );
    }
    
    public float InterpolateHeightBarycentric(Vector3 position, int closest)
    {
        var cells = FindDelaunayTriangle(closest, position);
        if (cells.Length < 3) return heights[closest];

        // normalized triangle verts
        Vector3 A = positions[cells[0]];
        Vector3 B = positions[cells[1]];
        Vector3 C = positions[cells[2]];

        Vector3 P = position.Normalized();

        // areas
        float areaTotal = TriArea(A, B, C);
        float areaA = TriArea(P, B, C);
        float areaB = TriArea(A, P, C);
        float areaC = TriArea(A, B, P);

        // barycentric weights
        float wA = areaA / areaTotal;
        float wB = areaB / areaTotal;
        float wC = areaC / areaTotal;

        // interpolate
        float hA = heights[cells[0]];
        float hB = heights[cells[1]];
        float hC = heights[cells[2]];

        return hA * wA + hB * wB + hC * wC;
    }
    
    public override void _Process(double delta)
    {
        Vector3I c_pos = (Vector3I)(camera.GlobalPosition / chunkSize);
        if (regenAroundCamera && c_pos != cameraChunkPos)
        {
            cameraChunkPos = c_pos;
            pauseChunkQueue = false;
            LoadChunksAroundCamera();
        }
    }

    
    public Vector3 ProjectToSurface(Vector3 startPos, int cell)
    {
        Vector3 dir = startPos.Normalized();

        float minR = planetRadius - terrainHeight * 2f;
        float maxR = planetRadius + terrainHeight * 2f;

        float a = minR;
        float b = maxR;

        for (int i = 0; i < 16; i++)
        {
            float mid = (a + b) * 0.5f;
            Vector3 p = dir * mid;

            float d = CalculateDensity(p, cell);

            if (d > 0)
                a = mid; // inside ground
            else
                b = mid; // in air
        }

        return dir * ((a + b) * 0.5f);
    }
    
    public override void _ExitTree()
    {
        chunkThread.WaitToFinish();
    }
}