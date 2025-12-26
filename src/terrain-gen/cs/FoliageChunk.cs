using Godot;
using System;
using System.Collections.Generic;

public partial class FoliageChunk : Node
{
    private const String SAVE_PATH = "user://chunks/";
    public string path = "";
    
    public List<Transform3D> transforms;
    public TerrainChunk chunk;


    public FoliageChunk(TerrainChunk c)
    {
        path = c.path;
        chunk = c;
    }

    public void Load()
    {
        GeneratePositions();
        
        //if (!TryLoadChunk()) GeneratePositions();
        //SaveData();
    }
    
    
    public void SaveData()
    {
        if (transforms == null) return;
        
        DirAccess.MakeDirRecursiveAbsolute(SAVE_PATH);
        
        using var file = FileAccess.Open(SAVE_PATH + path + "_fol.bin", FileAccess.ModeFlags.Write);
        file.StoreVar(transforms.Count);
        foreach (Transform3D d in transforms)
        {
            file.StoreVar(d);
        }
    }
    
    
    public bool TryLoadChunk()
    {
        string filepath = SAVE_PATH + path + "fol_.bin";
        if (!FileAccess.FileExists(filepath)) return false;

        using var file = FileAccess.Open(filepath, FileAccess.ModeFlags.Read);

        int count = (int)file.GetVar();
        transforms = new List<Transform3D>(count);
        
        for (int i = 0; i < count; i++)
            transforms.Add((Transform3D)file.GetVar());
        
        return true;
    }

    
    public void GeneratePositions()
    {
        transforms = new List<Transform3D>();
        
        Vector3 pos = chunk.chunkPos + Vector3.One * chunk.size / 2.0f;
        
        //pos = InterpHeight(pos);
        Vector3? v = RaymarchHeight(pos);
        if (!v.HasValue) return;
        pos = v.Value;
        
        
        Vector3 forward = pos.Normalized().Cross(Vector3.Right);
        if (forward.LengthSquared() < 0.0001f) forward = pos.Normalized().Cross(Vector3.Forward);
        forward = forward.Normalized();
        
        transforms.Add(new Transform3D(Basis.LookingAt(forward, pos.Normalized()), pos));
    }
    
    
    public Vector3? RaymarchHeight(Vector3 position)
    {
        Vector3 dir = -position.Normalized();
        
        while (true)
        {
            Vector3 newP = position - dir;
            if (chunk.WorldToVoxel(newP).X < 0) break;
            position = newP;
        }
        
        
        Vector3I startingVoxel = chunk.WorldToVoxel(position);
        if (startingVoxel.X < 0)
        {
            GD.Print("No tree: starting voxel invalid");
            return null;
        }
        
        // do not place tree if top is solid (there is ground above in a different chunk)
        if(chunk.data[chunk.GridToIDX(startingVoxel.X, startingVoxel.Y, startingVoxel.Z)] > 0)
        {
            GD.Print("No tree: top voxel solid");
            return null;
        }
        
        
        while (true)
        {
            position += dir;
            Vector3I voxelPos = chunk.WorldToVoxel(position);
            
            // left chunk with no valid height
            if (voxelPos.X < 0)
            {
                GD.Print("No tree. Left chunk without valid point");
                return null;
            }

            if (chunk.data[chunk.GridToIDX(voxelPos.X, voxelPos.Y, voxelPos.Z)] > 0)
            {
                GD.Print("Tree found surface");
                return position;
            }
        }
    }

    public Vector3 InterpHeight(Vector3 position)
    {
        int cell = chunk.tgen.CellIDFromNormal(position.Normalized(), chunk.cellID);

        float simHeight = chunk.InterpolateHeightBarycentric(position, cell);
        float height = chunk.tgen.planetRadius + (simHeight + (chunk.tgen.noise.GetNoise3Dv(position) -0.5f) * chunk.tgen.noiseScale) * chunk.tgen.terrainHeight;
        return position.Normalized() * height;
    }
}
