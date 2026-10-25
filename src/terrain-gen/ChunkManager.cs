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

    private GodotThread chunkThread = new GodotThread();
    
    public override void _Ready()
    {
        base._Ready();
        CreateChunks();
        chunkThread.Start(new Callable(this, MethodName.ChunkLoadLoop));
    }

    public override void _Input(InputEvent @event)
    {
        base._Input(@event);

        if (Input.IsActionJustPressed("debug_reload"))
        {
            seed = Random.Shared.Next();
            noise.Seed = seed;
            double time = Time.GetUnixTimeFromSystem();
            foreach (TerrainChunk chunk in chunks) chunk.dirty = true;
            GD.Print("Generated in " + (Time.GetUnixTimeFromSystem() - time) + " seconds.");
        }
        
    }
    
    public void CreateChunks()
    {
        foreach (TerrainChunk chunk in chunks) chunk.QueueFree();

        chunks = new List<TerrainChunk>();
        
        for(int x = 0; x < renderDistance; x++) for(int y = 0; y < renderDistance; y++) for (int z = 0; z < renderDistance; z++)
        {
            TerrainChunk chunk = new TerrainChunk(this, new Vector3I(x, y, z), chunkSize);
            AddChild(chunk);
            chunk.GlobalPosition = new Vector3(x, y, z) * chunkSize;
            chunks.Add(chunk);
        }
    }
    
    public void ChunkLoadLoop()
    {
        while(true)
            foreach (TerrainChunk chunk in chunks)
            {
                if (chunk.dirty)
                {
                    chunk.LoadChunk();
                }
            }
    }
    
    public override void _ExitTree()
    {
        chunkThread.WaitToFinish();
    }
}
