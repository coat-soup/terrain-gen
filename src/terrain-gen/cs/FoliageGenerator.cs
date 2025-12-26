using Godot;
using System;
using System.Linq;
using System.Collections.Generic;

public partial class FoliageGenerator : Node
{
    [Export] public Mesh treeMesh;
    [Export] public Node3D camera;
    [Export] public TerrainGenerator tgen;
    
    private MultiMeshInstance3D multiMesh;

    private int size = 32;
    private float spacing = 16f;

    private Transform3D[] transforms;

    private int transformCounter = 0;
    [Export] public int instanceCount = 1000;

    private Dictionary<String, FoliageChunk> foliageChunks;
    
    public override void _Ready()
    {
        multiMesh = new MultiMeshInstance3D();
        multiMesh.Multimesh = new MultiMesh();
        multiMesh.Multimesh.TransformFormat = MultiMesh.TransformFormatEnum.Transform3D;
        multiMesh.Multimesh.Mesh = treeMesh;
        multiMesh.Multimesh.InstanceCount = instanceCount;
        AddChild(multiMesh);

        transforms = new Transform3D[instanceCount];
        foliageChunks = new Dictionary<string, FoliageChunk>();
        
        tgen.TerrainChunkFinishedLoading += SpawnChunkFoliage;
    }

    public void SpawnChunkFoliage(TerrainChunk tChunk)
    {
        if (tChunk.voxelSizeMultiplier - 1 != 0 || tChunk.chunkEmpty) return;
        if (foliageChunks.ContainsKey(tChunk.path)) return;
        
        FoliageChunk fChunk = new FoliageChunk(tChunk);
        foliageChunks[fChunk.path] = fChunk;
        
        fChunk.Load();

        foreach (Transform3D t in fChunk.transforms)
        {
            transforms[transformCounter] = t;
            multiMesh.Multimesh.SetInstanceTransform(transformCounter, transforms[transformCounter]);
            transformCounter = (transformCounter + 1) % instanceCount;
        }
    }
}
