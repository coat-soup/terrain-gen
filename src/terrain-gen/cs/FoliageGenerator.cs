using Godot;
using System;
using System.Linq;
using System.Collections.Generic;

public partial class FoliageGenerator : Node
{
    [Export] public Mesh grassMesh;
    [Export] public Material material;
    [Export] public Node3D camera;
    [Export] public TerrainGenerator tgen;
    [Export] public float renderDist = 300;
    [Export] public float grassDistance = 50;
    [Export] public float maxSlope = 45;
    [Export] public float minOceanHeight = 50;

    [Export] public int chunkSize = 64;
    [Export] public float spacing = 16f;

    [Export] public ClimateZoneFoliageData[] climateData;
    
    private OctreeNode tree;

    [Export] public bool regenAroundCamera = true;
    public Vector3 cameraChunkPos;
    public Vector3 cameraPos; // so thread doesn't touch scene tree

    private int nNewChunksSpawned = 0;
    public int nTrees = 0;

    private GodotThread foliageThread;
    public Rid worldScenario;

    [Export] public int maxGrassInstances = 10000;
    public int grassMultiMeshInstanceCounter = 0;
    public MultiMeshInstance3D grassMultiMesh;
    public List<TerrainChunk> grassChunks;

    public Timer grassUpdateTimer;
    public bool shouldUpdateGrass;
    
    
    public override void _Ready()
    {
        tree = tgen.CreateRootNode(chunkSize);
        
        //cameraChunkPos = (Vector3I)(camera.GlobalPosition / chunkSize);
        //BuildTree(tree);
        //GD.Print("Spawned " + nNewChunksSpawned + " new foliage chunks");
        if (!regenAroundCamera) cameraPos = camera.GlobalPosition;

        worldScenario = GetTree().Root.GetWorld3D().Scenario;
        
        foreach(ClimateZoneFoliageData data in climateData) data.Setup();

        //grassRids = new List<Rid>();
        //grassTransforms = new List<Transform3D>();
        grassChunks = new List<TerrainChunk>();
        grassMultiMesh = new MultiMeshInstance3D();
        grassMultiMesh.Multimesh = new MultiMesh();
        grassMultiMesh.Multimesh.Mesh = grassMesh;
        grassMultiMesh.Multimesh.TransformFormat = MultiMesh.TransformFormatEnum.Transform3D;
        grassMultiMesh.Multimesh.InstanceCount = maxGrassInstances;
        AddChild(grassMultiMesh);

        grassUpdateTimer = new Timer();
        AddChild(grassUpdateTimer);
        grassUpdateTimer.Timeout += SetUpdateGrass;
        grassUpdateTimer.WaitTime = 0.5;
        grassUpdateTimer.Start();
        
        foliageThread = new GodotThread();
        foliageThread.Start(new Callable(this, MethodName.RunFoliageThread));
    }

    
    public void BuildTree(OctreeNode node)
    {
        node.cell_id = tgen.CellIDFromNormal(node.position + Vector3.One * node.sideLength / 2.0f, node.cell_id);
        
        bool inRange = (node.position + Vector3.One * node.sideLength/2.0f).DistanceTo(cameraPos) <= renderDist + node.sideLength * TerrainGenerator.HALFSQRT3;
        
        if (node.size > 0 && inRange && (node.depth == 0 || Mathf.Abs(tgen.SampleSDF(node.position + Vector3.One * node.sideLength/2.0f, node.cell_id)) <= node.sideLength * TerrainGenerator.HALFSQRT3)) // SHOULD SUBDIVIDE
        {
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
            if(node.children != null) for(int i = 0; i < node.children.Length; i++) CollapseNode(node.children[i]);
            
            if (node.size <= 2 && node.fChunk == null) SpawnNodeFoliage(node);
        }
    }
    
    
    public void CollapseNode(OctreeNode node)
    {
        if (node.fChunk != null)
        {
            nTrees -= node.fChunk.transforms.Count;
            node.fChunk.Unload();
            node.fChunk = null;
        }

        if (node.children != null) foreach (OctreeNode child in node.children)
        {
            CollapseNode(child);
        }

        node.children = null;
    }
    
    
    public void SpawnNodeFoliage(OctreeNode node)
    {
        nNewChunksSpawned++;
        
        FoliageChunk fChunk = new FoliageChunk(node.path, node.position, chunkSize * (node.size + 1), node.cell_id, this, tgen);
        node.fChunk = fChunk;
        
        fChunk.Load();
        nTrees += fChunk.transforms.Count;
    }


    public void SetUpdateGrass()
    {
        shouldUpdateGrass = true; //then called from thread
    }
    
    
    public void UpdateGrass()
    {
        shouldUpdateGrass = false;
        GD.Print("Updating Grass!");
        
        grassChunks.Clear();
        TravelChunkTreeForGrass(tgen.tree);
        
        
        grassMultiMeshInstanceCounter = 0;
        foreach (TerrainChunk chunk in grassChunks)
        {
            if (chunk.chunkEmpty || chunk.vertices == null) continue;
            for (int i = 0; i < chunk.vertices.Length; i+=3)
            {
                if (grassMultiMeshInstanceCounter >= maxGrassInstances) break;
                
                Vector3 wPos = chunk.chunkPos + (chunk.vertices[i] + chunk.vertices[i+1] + chunk.vertices[i+2])/3.0f;
                
                Vector3 manhattanDiff = (cameraPos - wPos).Abs();
                if (manhattanDiff.X > grassDistance || manhattanDiff.Y > grassDistance || manhattanDiff.Z > grassDistance) continue;
                
                if (chunk.normals[i].Dot(wPos.Normalized()) > 0.9)
                {
                    uint h = HashVector((Vector3I)(wPos * 3.0f));
                    float angle  = (h & 0xffff) / 65535f * Mathf.Tau;
                    float radius = ((h >> 16) & 0xffff) / 65535f * 0.5f;

                    Vector3 normal = wPos.Normalized();

                    // build tangent basis
                    Vector3 tangent = normal.Cross(
                        Math.Abs(normal.Y) < 0.99f ? Vector3.Up : Vector3.Right
                    ).Normalized();

                    Vector3 bitangent = normal.Cross(tangent);

                    // apply polar offset
                    Vector3 offset = Mathf.Cos(angle) * tangent * radius + Mathf.Sin(angle) * bitangent * radius;

                    wPos += offset;
                    
                    Vector3 forward = Mathf.Cos(angle) * tangent + Mathf.Sin(angle) * bitangent;
                    
                    grassMultiMesh.Multimesh.SetInstanceTransform(grassMultiMeshInstanceCounter, new Transform3D(Basis.LookingAt(forward, wPos.Normalized()), wPos));
                    grassMultiMeshInstanceCounter++;
                }
            }
        }

        grassMultiMesh.Multimesh.VisibleInstanceCount = grassMultiMeshInstanceCounter;
    }

    static uint HashVector(Vector3I p)
    {
        unchecked
        {
            uint x = (uint)(p.X * 73856093);
            uint y = (uint)(p.Y * 19349663);
            uint z = (uint)(p.Z * 83492791);
            return x ^ y ^ z;
        }
    }
    
    public void TravelChunkTreeForGrass(OctreeNode node)
    {
        bool inRange = (node.position + Vector3.One * node.sideLength/2.0f).DistanceTo(cameraPos) <= grassDistance + node.sideLength * 0.86602540378f;

        if (!inRange) return;
        
        if(node.children == null && node.chunk != null) grassChunks.Add(node.chunk);
        else if(node.children != null)
        {
            foreach(OctreeNode child in node.children) TravelChunkTreeForGrass(child);
        }
    }
    
    
    public override void _Process(double delta)
    {
        base._Process(delta);
        cameraPos = camera.GlobalPosition;
    }

    
    private void RunFoliageThread()
    {
        if (!regenAroundCamera)BuildTree(tree); // do only once
        
        while (true)
        {
            if (shouldUpdateGrass) UpdateGrass();
            
            Vector3I c_pos = (Vector3I)(cameraPos / chunkSize);
            if (regenAroundCamera && c_pos != cameraChunkPos)
            {
                nNewChunksSpawned = 0;
                cameraChunkPos = c_pos;
                BuildTree(tree);
                GD.Print("Spawned " + nNewChunksSpawned + " new foliage chunks");
            }
        }
    }

    public override void _ExitTree()
    {
        base._ExitTree();
        foliageThread.WaitToFinish();
    }
}
