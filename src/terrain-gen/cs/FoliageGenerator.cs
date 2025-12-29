using Godot;
using System;
using System.Linq;
using System.Collections.Generic;

public partial class FoliageGenerator : Node
{
    [Export] public Mesh treeMesh;
    [Export] public Material material;
    [Export] public Node3D camera;
    [Export] public TerrainGenerator tgen;
    [Export] public float renderDist = 300;
    [Export] public float maxSlope = 45;
    [Export] public float minOceanHeight = 50;

    [Export] public int chunkSize = 64;
    [Export] public float spacing = 16f;
    
    private OctreeNode tree;

    [Export] public bool regenAroundCamera = true;
    public Vector3 cameraChunkPos;
    public Vector3 cameraPos; // so thread doesn't touch scene tree

    private int nNewChunksSpawned = 0;
    public int nTrees = 0;

    private GodotThread foliageThread;
    public Rid worldScenario;
    
    
    public override void _Ready()
    {
        tree = tgen.CreateRootNode(chunkSize);
        
        //cameraChunkPos = (Vector3I)(camera.GlobalPosition / chunkSize);
        //BuildTree(tree);
        //GD.Print("Spawned " + nNewChunksSpawned + " new foliage chunks");
        if (!regenAroundCamera) cameraPos = camera.GlobalPosition;

        worldScenario = GetTree().Root.GetWorld3D().Scenario;
        
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
