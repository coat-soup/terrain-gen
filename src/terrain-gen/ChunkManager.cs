using Godot;
using System;
using System.Collections.Generic;

public partial class ChunkManager : Node
{
    [Export] public int seed;
    [Export] public FastNoiseLite noise;
    [Export] public ShaderMaterial material;

    [Export] public int chunkSize = 64;
    
    private List<TerrainChunk> chunks = new List<TerrainChunk>();

    [Export] public int renderDistance = 4;

    public override void _Ready()
    {
        base._Ready();
        LoadChunks();
    }

    public void LoadChunks()
    {
        foreach (TerrainChunk chunk in chunks) chunk.QueueFree();

        chunks = new List<TerrainChunk>();
        
        for(int x = 0; x < renderDistance; x++) for(int y = 0; y < renderDistance; y++) for (int z = 0; z < renderDistance; z++)
        {
            TerrainChunk chunk = new TerrainChunk(this, new Vector3I(x, y, z), chunkSize);
            AddChild(chunk);
            chunk.GlobalPosition = new Vector3(x, y, z) * chunkSize;
            chunk.LoadChunk();
            chunks.Add(chunk);
        }
    }
}
