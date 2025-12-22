using System;
using System.Linq;
using Godot;
using Godot.Collections;

public partial class TerrainGenerator : Node
{
    [Export] public float planetRadius = 12000.0f;
    [Export] public float terrainHeight = 1000.0f;
    [Export] public int chunkSize = 32;
    [Export] public float renderDist = 100.0f;
    
    [Export] public int debug_tree_depth_limit = 4;

    [Export] public Material terrainMaterial;
    
    public Array<Array<int>> neighbours;
    public Vector3[] positions;
    public float[] heights;
    public Vector3[] windDirs;
    public float[] precipitations;
    public int[] climateZoneIDs;
    
    OctreeNode tree;
    private int n_nodes;
    private int n_small_leaves;
    private int n_loaded_chunks;

    [Export] public Node3D camera;
    private Vector3I cameraChunkPos;
    
    const float HALFSQRT3 = 0.86602540378f; // Sqrt(3)/2
    
    
    public void CreateTreeFromDataArrays(Array<Array<int>> _neighbours, Vector3[] _positions, float[] _heights, Vector3[] _windDirs, float[] _precipitations, int[] _climateZoneIDs)
    {
        neighbours = _neighbours;
        positions = _positions;
        heights = _heights;
        windDirs = _windDirs;
        precipitations = _precipitations;
        climateZoneIDs = _climateZoneIDs;
        GD.Print("Creating tree from data. Got heights size " + _heights.Length);
        
        // create root node
        float margin = terrainHeight * 1.2f;
        float diameter = 2.0f * planetRadius + 2.0f * margin;
        float s = chunkSize;
        int si = 0;
        while (s < diameter) { s *= 2.0f; si += 1;}
        Vector3 rootPos = -Vector3.One * s / 2.0f;
        tree = new OctreeNode(rootPos, s, 0, si, 0);

        double time = Time.GetUnixTimeFromSystem();
        
        GD.Print("Root node size: ", tree.size);
        n_nodes = 0;
        n_small_leaves = 0;
        BuildTree(tree);
        GD.Print("Tree finished with " + n_nodes + " nodes (" + n_small_leaves + " size 0 leaves) in " + (Time.GetUnixTimeFromSystem() - time) + " seconds.");
    }

    
    public void LoadChunksAroundCamera()
    {
        double time = Time.GetUnixTimeFromSystem();

        n_loaded_chunks = 0;
        
        terrainMaterial.Set("shader_parameter/planet_radius", planetRadius);
        terrainMaterial.Set("shader_parameter/terrain_height", terrainHeight);
        
        LoadChunks(tree, camera.Position);
        GD.Print("Loaded " + n_loaded_chunks + " chunks in " + (Time.GetUnixTimeFromSystem() - time) + " seconds.");
    }
    
    
    public void BuildTree(OctreeNode node)
    {
        n_nodes++;
        if (node.size == 0) n_small_leaves++;
        
        node.cell_id = CellIDFromNormal(node.position + Vector3.One * node.sideLength / 2.0f, node.cell_id);
        
        if (node.size == 0) return;
        if (node.depth >= debug_tree_depth_limit) return;
        
        bool inRange = (node.position + Vector3.One * node.sideLength/2.0f).DistanceTo(camera.GlobalPosition) <= renderDist + node.sideLength * HALFSQRT3;
        if (!inRange) return;
        
        if (node.depth == 0 || Mathf.Abs(SampleSDF(node.position + Vector3.One * node.sideLength/2.0f, node.cell_id)) <= node.sideLength * HALFSQRT3)
        {
            Vector3[] childPositions = [new Vector3(0,0,0), new Vector3(0,0,1), new Vector3(0,1,0), new Vector3(0,1,1), new Vector3(1,0,0), new Vector3(1,0,1), new Vector3(1,1,0), new Vector3(1,1,1)];
            node.children = new OctreeNode[8];
            for(int i = 0; i < 8; i++)
            {
                node.children[i] = new OctreeNode(node.position + node.sideLength * childPositions[i] / 2.0f, node.sideLength / 2.0f, node.depth + 1, node.size - 1, node.cell_id, node);
            }
            foreach(OctreeNode child in node.children) BuildTree(child);
        }
    }
    
    
    public void LoadChunks(OctreeNode node, Vector3 cameraPos, String path = "")
    {
        bool inRange = (node.position + Vector3.One * node.sideLength/2.0f).DistanceTo(cameraPos) <= renderDist + node.sideLength * HALFSQRT3;
        //inRange = true;
        if (!inRange && !node.childLoaded) return;
        if (node.children == null)
        {
            if (inRange)
            {
                if (node.chunk == null)
                {
                    n_loaded_chunks++;
                    
                    node.chunk = new TerrainChunk(node.position, chunkSize, this, node.cell_id, (int)Mathf.Pow(2, node.size), path);
                    node.chunk.Load();
                    node.SetLoaded(true);
                    Callable.From(() => { AddChild(node.chunk); }).CallDeferred();
                    node.chunk.Position = node.position;
                }
            }
            else if(node.chunk != null)
            {
                node.chunk.Unload();
                node.chunk = null;
                node.SetLoaded(false);
            }
        }
        else for(int i = 0; i < node.children.Length; i++) LoadChunks(node.children[i], cameraPos, path + i.ToString());
    }
        
    
    public float SampleSDF(Vector3 position, int cell = -1)
    {
        //return planetRadius - position.Length();
        
        if (cell == -1) cell = CellIDFromNormal(position.Normalized());
        return planetRadius + terrainHeight * heights[cell] - position.Length();
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

    
    public override void _Process(double delta)
    {
        Vector3I c_pos = (Vector3I)(camera.GlobalPosition / chunkSize);
        if (c_pos != cameraChunkPos)
        {
            cameraChunkPos = c_pos;
            LoadChunksAroundCamera();
        }
    }
}