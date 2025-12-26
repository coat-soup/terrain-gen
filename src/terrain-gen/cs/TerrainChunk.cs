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
    public int size;
    public int voxelSizeMultiplier;
    public Vector3[] vertices;
    public Vector3[] normals;
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
        
        Godot.Collections.Dictionary<string, Vector3[]> mc = MarchingCubes.Generate(data, new Vector3I(size, size, size), 0.0f, voxelSizeMultiplier);
        vertices = mc["vertices"];
        normals = mc["normals"];

        if (vertices.Length < 3) return;
        
        
        ArrayMesh arrayMesh = new ArrayMesh();
        Godot.Collections.Array arrays = [];
        arrays.Resize((int)Mesh.ArrayType.Max);
        arrays[(int)Mesh.ArrayType.Vertex] = vertices;
        arrays[(int)Mesh.ArrayType.Normal] = normals;
        
        arrayMesh.AddSurfaceFromArrays(Mesh.PrimitiveType.Triangles, arrays);
        Mesh = arrayMesh;

        MaterialOverlay = tgen.terrainMaterial;

        finishedLoading = true;
        //EmitSignal(finished);
    }

    
    public void Load()
    {
        data = new float[size * size * size];
        
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
            float density = tgen.CalculateDensity(wPos, cellID);
            data[GridToIDX(x, y, z)] = density;

            System.Threading.Interlocked.Or(ref hasFilled, density < 0 ? 1 : 0);
            System.Threading.Interlocked.Or(ref hasEmpty,  density > 0 ? 1 : 0);
        }
    }
    
    
    public struct NormalKey : IEquatable<NormalKey>
    {
        private float precision = 0.0001f;

        public int x;
        public int y;
        public int z;

        public NormalKey(Vector3 normal, int chunkSize)
        {
            normal = normal.Normalized();
            x = (int)(normal.X / precision);
            y = (int)(normal.Y / precision);
            z = (int)(normal.Z / precision);
            precision *= Mathf.Pow(4f, chunkSize);
        }

        public bool Equals(NormalKey other) =>
            x == other.x && y == other.y && z == other.z;

        public override bool Equals(object obj) =>
            obj is NormalKey other && Equals(other);

        public override int GetHashCode() =>
            HashCode.Combine(x, y, z);
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
    
    
    public float InterpolateHeight2(Vector3 worldPos, int cell)
    {
        Vector3 p = worldPos.Normalized();

        // find closest neighbor
        int closest = -1;
        float best = -1.0f;

        for (int i = 0; i < tgen.neighbours[cell].Count; i++)
        {
            int n = tgen.neighbours[cell][i];
            float d = p.Dot(tgen.positions[n]);
            if (d > best)
            {
                best = d;
                closest = n;
            }
        }

        // angular distances
        float d0 = 1.0f - p.Dot(tgen.positions[cell]);
        float d1 = 1.0f - p.Dot(tgen.positions[closest]);

        // normalize blend
        float t = d0 / (d0 + d1);

        return Mathf.Lerp(tgen.heights[cell], tgen.heights[closest], t);
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


}
