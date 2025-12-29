using Godot;
using System;
using System.Collections.Generic;

public partial class FoliageChunk : Node
{
    private const String SAVE_PATH = "user://chunks/";
    public string path = "";
    
    public List<Transform3D> transforms;
    public TerrainGenerator tgen;
    public FoliageGenerator fgen;
    public Vector3 chunkPos;
    public int size;
    public int cellID;
    private Rid[] rids;
    

    public FoliageChunk(String p, Vector3 pos, int s, int cid, FoliageGenerator f, TerrainGenerator t)
    {
        path = p;
        chunkPos = pos;
        size = s;
        cellID = cid;
        fgen = f;
        tgen = t;
    }

    public void Load()
    {
        if (!TryLoadChunk()) GeneratePositions();
        SaveData();

        ClimateZoneFoliageData climateData = null;
        foreach (ClimateZoneFoliageData data in fgen.climateData)
        {
            if (tgen.climateZoneIDs[cellID] == data.climateZoneID) climateData = data;
        }
        if (climateData == null) return;
        
        rids = new Rid[transforms.Count];
        for(int i = 0; i < transforms.Count; i++)
        {
            rids[i] = RenderingServer.InstanceCreate();
            RenderingServer.InstanceSetBase(rids[i], climateData.SelectMesh().GetRid());
            RenderingServer.InstanceSetScenario(rids[i], fgen.worldScenario);
            RenderingServer.InstanceSetTransform(rids[i], transforms[i]);
        }
    }

    
    public void Unload()
    {
        if (rids == null) return;
        for(int i = 0; i < rids.Length; i++) RenderingServer.FreeRid(rids[i]);
        rids = [];
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
        string filepath = SAVE_PATH + path + "_fol.bin";
        if (!FileAccess.FileExists(filepath)) return false;

        using var file = FileAccess.Open(filepath, FileAccess.ModeFlags.Read);

        int count = (int)file.GetVar();
        transforms = new List<Transform3D>(count);
        
        for (int i = 0; i < count; i++)
            transforms.Add((Transform3D)file.GetVar());
        
        return true;
    }

    
    public static void ClearAllChunkData()
    {
        if (!DirAccess.DirExistsAbsolute(SAVE_PATH))
        {
            GD.PushError("Failed to clear chunk data. Could not find " + SAVE_PATH);
            return;
        }
        
        using var dir = DirAccess.Open(SAVE_PATH);
        if (dir == null)
            return;

        dir.ListDirBegin();
        while (true)
        {
            string file = dir.GetNext();
            if (file == "") break;
            if (!file.EndsWith("_fol.bin")) continue;

            DirAccess.RemoveAbsolute(SAVE_PATH + file);
        }
        dir.ListDirEnd();
    }
    
    
    public void GeneratePositions()
    {
        Random rand = new Random();
        int randOffset = 10;
        
        transforms = new List<Transform3D>();
        
        Vector3 chunkCenter = chunkPos + Vector3.One * size * 0.5f;
        Vector3 up = chunkCenter.Normalized();

        Vector3 tangent = up.Cross(Vector3.Right);
        if (tangent.LengthSquared() < 0.0001f) tangent = up.Cross(Vector3.Forward);
        tangent = tangent.Normalized();

        Vector3 bitangent = up.Cross(tangent).Normalized();

        float padding = 0.3f * size; // for diagonal shadow
        
        for(int x = -(int)(padding / fgen.spacing); x < (size + padding) / fgen.spacing; x++)
        for (int y = -(int)(padding / fgen.spacing); y < (size + padding) / fgen.spacing; y++)
        {
            Vector2 offset = new Vector2(
                (x + 0.5f) * fgen.spacing - fgen.chunkSize * 0.5f,
                (y + 0.5f) * fgen.spacing - fgen.chunkSize * 0.5f
            );

            Vector3 pos = chunkCenter + tangent * offset.X + bitangent * offset.Y;
            pos += new Vector3(rand.Next(randOffset * 10) / 10.0f, rand.Next(randOffset * 10) / 10.0f, rand.Next(randOffset * 10) / 10.0f);

            pos = ProjectToSurface(pos);
            if(pos.X < chunkPos.X || pos.X >= chunkPos.X + size || pos.Y < chunkPos.Y || pos.Y >= chunkPos.Y + size || pos.Z < chunkPos.Z || pos.Z >= chunkPos.Z + size) continue;

            if (pos.Length() - tgen.planetRadius < fgen.minOceanHeight) continue;
            
            Vector3 forward = pos.Normalized().Cross(Vector3.Right);
            if (forward.LengthSquared() < 0.0001f) forward = pos.Normalized().Cross(Vector3.Forward);
            forward = forward.Normalized();
            
            float slope = Mathf.RadToDeg(SurfaceNormal(pos).AngleTo(pos.Normalized()));
            if (slope > fgen.maxSlope) continue;
            
            transforms.Add(new Transform3D(Basis.LookingAt(forward, pos.Normalized()), pos));
        }
    }
    
    Vector3 SurfaceNormal(Vector3 surfacePos)
    {
        Vector3 up = surfacePos.Normalized();

        Vector3 t1 = up.Cross(Vector3.Up);
        if (t1.LengthSquared() < 1e-4f)
            t1 = up.Cross(Vector3.Right);
        t1 = t1.Normalized();

        Vector3 t2 = up.Cross(t1);

        float eps = 1;

        Vector3 p1 = ProjectToSurface(surfacePos + t1 * eps);
        Vector3 p2 = ProjectToSurface(surfacePos + t2 * eps);

        return (p1 - surfacePos).Cross(p2 - surfacePos).Normalized();
    }


    
    
    /*public Vector3? RaymarchHeight(Vector3 position)
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
    }*/
    
    
    Vector3 ProjectToSurface(Vector3 startPos)
    {
        Vector3 dir = startPos.Normalized();

        float minR = tgen.planetRadius - tgen.terrainHeight * 2f;
        float maxR = tgen.planetRadius + tgen.terrainHeight * 2f;

        float a = minR;
        float b = maxR;

        for (int i = 0; i < 16; i++) // 16 iterations = sub-millimeter accuracy
        {
            float mid = (a + b) * 0.5f;
            Vector3 p = dir * mid;

            float d = tgen.CalculateDensity(p, cellID);

            if (d > 0)
                a = mid; // inside ground
            else
                b = mid; // in air
        }

        return dir * ((a + b) * 0.5f);
    }

    public override void _ExitTree()
    {
        Unload();
    }
}
