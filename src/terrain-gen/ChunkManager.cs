using Godot;
using System;
using System.Collections.Generic;

public partial class ChunkManager : Node
{
    [Export] public int seed;
    [Export] public FastNoiseLite noise;
    [Export] public ShaderMaterial material;

    [Export] public int generationDistance = 500;
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
        foreach (TerrainChunk c in chunks) c.QueueFree();

        chunks = new List<TerrainChunk>();

        int max_lod = 0;
        while (chunkSize * Math.Pow(2, max_lod) < generationDistance)
        {
            max_lod += 1;
        }
        
        TerrainChunk chunk = new TerrainChunk(this, Vector3I.Zero, chunkSize, max_lod);
        AddChild(chunk);
        chunks.Add(chunk);
        RecursiveAddChildChunks(chunk);
    }

    public void RecursiveAddChildChunks(TerrainChunk chunk)
    {
        bool subdivide = chunk.chunkLOD > 0 && chunk.IsPointInBounds(new Vector3(5,5,5));
        if (subdivide)
        {
            chunk.childChunks = new TerrainChunk[8];
            for(int x = 0; x < 2; x++) for(int y = 0; y < 2; y++) for (int z = 0; z < 2; z++)
            {
                TerrainChunk childChunk = new TerrainChunk(this, chunk.chunkPos + new Vector3I(x,y,z) * (int)Mathf.Pow(2, chunk.chunkLOD-1), chunkSize, chunk.chunkLOD-1, chunk);
                AddChild(childChunk);
                childChunk.GlobalPosition = childChunk.chunkPos * chunkSize;
                chunks.Add(childChunk);
                chunk.childChunks[x + y * 2 + z * 2 * 2] = childChunk;
                RecursiveAddChildChunks(childChunk);
            }
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
