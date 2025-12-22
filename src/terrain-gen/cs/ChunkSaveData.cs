using Godot;
using System;

public partial class ChunkSaveData : Resource
{
    private const String SAVE_PATH = "user://chunks/";
    
    [Export] public float[] data;
    [Export] public bool isEmpty;

    public static void SaveData(TerrainChunk chunk)
    {
        DirAccess.MakeDirRecursiveAbsolute(SAVE_PATH);
        
        using var file = FileAccess.Open(SAVE_PATH + chunk.path + ".bin", FileAccess.ModeFlags.Write);
        file.Store8(chunk.chunkEmpty ? (byte)1 : (byte)0);
        if (!chunk.chunkEmpty)
            foreach (float d in chunk.data)
            {
                file.StoreFloat(d);
            }
    }
    
    public static bool TryLoadChunk(TerrainChunk chunk)
    {
        string path = SAVE_PATH + chunk.path + ".bin";
        if (!FileAccess.FileExists(path)) return false;

        using var file = FileAccess.Open(path, FileAccess.ModeFlags.Read);

        chunk.chunkEmpty = file.Get8() == 1;
        
        if (!chunk.chunkEmpty)
            for (int i = 0; i < chunk.data.Length; i++)
                chunk.data[i] = file.GetFloat();
        
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
            if (file == "")
                break;

            DirAccess.RemoveAbsolute(SAVE_PATH + file);
        }
        dir.ListDirEnd();
    }

}
