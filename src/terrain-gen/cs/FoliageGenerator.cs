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
    
    private MultiMeshInstance3D multiMesh;

    [Export] public int chunkSize = 64;
    [Export] public float spacing = 16f;

    private Transform3D[] transforms;

    private int transformCounter = 0;
    [Export] public int instanceCount = 10000;

    private OctreeNode tree;

    [Export] public bool regenAroundCamera = true;
    public Vector3 cameraChunkPos;

    private int nNewChunksSpawned = 0;
    
    
    public override void _Ready()
    {
        multiMesh = new MultiMeshInstance3D();
        multiMesh.Multimesh = new MultiMesh();
        multiMesh.Multimesh.TransformFormat = MultiMesh.TransformFormatEnum.Transform3D;
        multiMesh.Multimesh.Mesh = treeMesh;
        //for(int i = 0; i < multiMesh.Multimesh.Mesh._GetSurfaceCount(); i++) multiMesh.Multimesh.Mesh._SurfaceSetMaterial(i, material);
        multiMesh.MaterialOverlay = material;
        multiMesh.Multimesh.InstanceCount = instanceCount;
        AddChild(multiMesh);

        transforms = new Transform3D[instanceCount];

        cameraChunkPos = (Vector3I)(camera.GlobalPosition / chunkSize);
        
        tree = tgen.CreateRootNode(chunkSize);
        BuildTree(tree);
        GD.Print("Spawned " + nNewChunksSpawned + " new foliage chunks");
    }

    
    public void BuildTree(OctreeNode node)
    {
        node.cell_id = tgen.CellIDFromNormal(node.position + Vector3.One * node.sideLength / 2.0f, node.cell_id);
        
        bool inRange = (node.position + Vector3.One * node.sideLength/2.0f).DistanceTo(camera.GlobalPosition) <= renderDist + node.sideLength * TerrainGenerator.HALFSQRT3;
        
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

        foreach (Transform3D t in fChunk.transforms)
        {
            transforms[transformCounter] = t;
            multiMesh.Multimesh.SetInstanceTransform(transformCounter, transforms[transformCounter]);
            transformCounter = (transformCounter + 1) % instanceCount;
        }
    }
    
    public override void _Process(double delta)
    {
        Vector3I c_pos = (Vector3I)(camera.GlobalPosition / chunkSize);
        if (regenAroundCamera && c_pos != cameraChunkPos)
        {
            nNewChunksSpawned = 0;
            cameraChunkPos = c_pos;
            BuildTree(tree);
            GD.Print("Spawned " + nNewChunksSpawned + " new foliage chunks");
        }
    }
}
