using Godot;
using System;
using System.Collections.Generic;


public partial class TerrainChunk : MeshInstance3D
{
    public Signal finished;
    
    public string path = ""; // eg. 401057 is root.child[4].child[0].child[1].child[0].child[5].child[7]
                             // TODO: make not a string probably
                             // NOTE: this isn't implemented. It's just an idea for saving/loading
    public Vector3 chunkPos;
    public float[] data;
    public uint[] materialData;
    public int size;
    public int voxelSizeMultiplier;
    public Vector3[] vertices;
    public Vector3[] normals;
    public Color[] colours;
    public TerrainGenerator tgen;
    public int cellID;

    public bool chunkEmpty;
    public bool unloadQueued = false;
    public bool finishedLoading = false;
    
    int hasFilled = 0;
    int hasEmpty = 0;
    
    public TerrainChunk(Vector3 pos, int s, TerrainGenerator gen, int cID, int sizeMult, String p)
    {
        chunkPos = pos;
        size = s;
        tgen = gen;
        cellID = cID;
        voxelSizeMultiplier = sizeMult;
        path = p;

        size += 1; // seam padding
    }
    
    
    public void GenerateMesh()
    {
        if (chunkEmpty) return;
        
        MCData mc = MarchingCubes.Generate(data, materialData, 14, new Vector3I(size, size, size), 0.0f, voxelSizeMultiplier);
        vertices = mc.vertices;
        normals = mc.normals;
        colours = mc.colours;

        if (vertices.Length < 3) return;
        
        
        ArrayMesh arrayMesh = new ArrayMesh();
        Godot.Collections.Array arrays = [];
        arrays.Resize((int)Mesh.ArrayType.Max);
        arrays[(int)Mesh.ArrayType.Vertex] = vertices;
        arrays[(int)Mesh.ArrayType.Normal] = normals;
        arrays[(int)Mesh.ArrayType.Color] = colours;
        
        arrayMesh.AddSurfaceFromArrays(Mesh.PrimitiveType.Triangles, arrays);
        Mesh = arrayMesh;

        MaterialOverlay = tgen.terrainMaterial;

        finishedLoading = true;
        //EmitSignal(finished);
    }

    
    public void Load()
    {
        data = new float[size * size * size];
        materialData = new uint[data.Length];
        
        bool loaded = ChunkSaveData.TryLoadChunk(this);

        if (!loaded)
        {
            long taskId = WorkerThreadPool.AddGroupTask(Callable.From<int>(PopulateData), size);
            WorkerThreadPool.WaitForGroupTaskCompletion(taskId);
            //PopulateData();
            
            chunkEmpty = !(hasEmpty == 1 && hasFilled == 1);
            
            ChunkSaveData.SaveData(this);
        }
        
        GenerateMesh();

        //tgen.EmitSignal(TerrainGenerator.SignalName.TerrainChunkFinishedLoading, this);
    }

    
    public void Unload()//OctreeNode[] dependencies)
    {
        /*
        unloadQueued = true;

        foreach (OctreeNode node in dependencies)
        {
            if (node.chunkQueued)
        }*/
        
        QueueFree();
        // TODO: save data to disk
    }

    
    public int GridToIDX(int x, int y, int z)
    {
        return x + y * size + z * size * size;
    }

    
    public void PopulateData(int x)
    {
        //for(int x = 0; x < size; x++)
        for(int y = 0; y < size; y++)
        for (int z = 0; z < size; z++)
        {
            Vector3 wPos = chunkPos + new Vector3(x, y, z) * voxelSizeMultiplier;
            int cell = tgen.CellIDFromNormal(wPos, cellID);
            float density = tgen.CalculateDensity(wPos, cell, false);
            data[GridToIDX(x, y, z)] = density;
            materialData[GridToIDX(x, y, z)] = (uint)tgen.climateZoneIDs[cell];

            System.Threading.Interlocked.Or(ref hasFilled, density < 0 ? 1 : 0);
            System.Threading.Interlocked.Or(ref hasEmpty,  density > 0 ? 1 : 0);
        }
    }

    

    public float InterpolateHeight(Vector3 worldPos, int cell)
    {
        float height = 0.0f;
        float weight = 0.0f;

        for (int i = 0; i < tgen.neighbours[cell].Count; i++)
        {
            int n = tgen.neighbours[cell][i];

            float d = 1.0f - worldPos.Normalized().Dot(tgen.positions[n]);
            
            float w = 1.0f/d;
            height += tgen.heights[n] * w;
            weight += w;
        }
        
        return height / weight;
    }

    
    public Vector3I WorldToVoxel(Vector3 p)
    {
        Vector3 rel = (p - chunkPos) / voxelSizeMultiplier;

        int vx = Mathf.FloorToInt(rel.X);
        int vy = Mathf.FloorToInt(rel.Y);
        int vz = Mathf.FloorToInt(rel.Z);

        if (vx < 0 || vx >= size ||
            vy < 0 || vy >= size ||
            vz < 0 || vz >= size)
        {
            return new Vector3I(-1, -1, -1);
        }

        return new Vector3I(vx, vy, vz);
    }

    
    public Color[] CalculateVertexColours(Vector3[] verts)
    {
        Color[] colours = new Color[verts.Length];

        for (int i = 0; i < verts.Length; i++)
        {
            colours[i] = new Color(tgen.climateZoneIDs[cellID] / 14.0f, 0, 0); // there are 15 climate zones
        }

        return colours;
    }

}
