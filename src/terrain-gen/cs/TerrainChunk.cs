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

            int cell = tgen.CellIDFromNormal(wPos.Normalized(), cellID);

            float simHeight = InterpolateHeightBarycentric(wPos, cell);
            float height = tgen.planetRadius + (simHeight + (tgen.noise.GetNoise3Dv(wPos) -0.5f) * tgen.noiseScale) * tgen.terrainHeight;
            float density = height - wPos.Length();

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

    
    
    public static bool IsPointInSphericalTriangle( Vector3 p,  Vector3 a,  Vector3 b,  Vector3 c){
        Vector3 ab = a.Cross(b);
        Vector3 bc = b.Cross(c);
        Vector3 ca = c.Cross(a);
            
        float s1 = ab.Dot(p);
        float s2 = bc.Dot(p);
        float s3 = ca.Dot(p);

        return (s1 >= 0.0 && s2 >= 0.0 && s3 >= 0.0) || (s1 <= 0.0 && s2 <= 0.0 && s3 <= 0.0);
    }
    
    
    public int[] FindDelaunayTriangle(int closest, Vector3 p)
    {
        Vector3 center = tgen.positions[closest];
        Godot.Collections.Array<int> neighbours = tgen.neighbours[closest];

        for(int i = 0; i < neighbours.Count; i++)
        {
            Vector3 b = tgen.positions[neighbours[i]];
            Vector3 c = tgen.positions[neighbours[(i + 1) % neighbours.Count]];

            if (IsPointInSphericalTriangle(p, center, b, c))
                return [closest, neighbours[i], neighbours[(i + 1) % neighbours.Count]];
        }

        return [closest, neighbours[0], neighbours[1]];
    }

    public static float TriArea(Vector3 a, Vector3 b, Vector3 c)
    {
        return Mathf.Atan2(
            a.Dot(b.Cross(c)),
            1.0f + a.Dot(b) + b.Dot(c) + c.Dot(a)
        );
    }
    
    public float InterpolateHeightBarycentric(Vector3 position, int closest)
    {
        var cells = FindDelaunayTriangle(closest, position);
        if (cells.Length < 3) return tgen.heights[closest];

        // normalized triangle verts
        Vector3 A = tgen.positions[cells[0]];
        Vector3 B = tgen.positions[cells[1]];
        Vector3 C = tgen.positions[cells[2]];

        Vector3 P = position.Normalized();

        // areas
        float areaTotal = TriArea(A, B, C);
        float areaA = TriArea(P, B, C);
        float areaB = TriArea(A, P, C);
        float areaC = TriArea(A, B, P);

        // barycentric weights
        float wA = areaA / areaTotal;
        float wB = areaB / areaTotal;
        float wC = areaC / areaTotal;

        // interpolate
        float hA = tgen.heights[cells[0]];
        float hB = tgen.heights[cells[1]];
        float hC = tgen.heights[cells[2]];

        return hA * wA + hB * wB + hC * wC;
    }
}
