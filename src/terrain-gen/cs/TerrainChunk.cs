using Godot;
using System;
using System.Collections.Generic;


public partial class TerrainChunk : MeshInstance3D
{
    public string path = ""; // eg. 401057 is root.child[4].child[0].child[1].child[0].child[5].child[7]
                             // TODO: make not a string probably
                             // NOTE: this isn't implemented. It's just an idea for saving/loading
    public Vector3 chunkPos;
    public float[] data;
    public int size;
    public Vector3[] vertices;
    public Vector3[] normals;
    public TerrainGenerator tgen;
    public int cellID;

    private bool chunkEmpty;
    
    
    public TerrainChunk(Vector3 pos, int s, TerrainGenerator gen, int cID)
    {
        chunkPos = pos;
        size = s;
        tgen = gen;
        cellID = cID;

        size += 1; // seam padding
    }
    
    
    public void Generate()
    {
        //var debugBox = new CsgBox3D();
        //Callable.From(() => { AddChild(debugBox); }).CallDeferred();
        //debugBox.Size = new Vector3(size, size, size);
        //debugBox.Position = debugBox.Size / 2.0f;
        
        data = new float[size * size * size];
        PopulateData();
        if (chunkEmpty) return;
        
        //GD.Print("chunk data not homogenous");
        
        Godot.Collections.Dictionary<string, Vector3[]> mc = MarchingCubes.Generate(data, new Vector3I(size, size, size));
        //GD.Print(mc);
        vertices = mc["vertices"];
        normals = mc["normals"];

        if (vertices.Length < 3)
        {
            // chunk is empty
            return;
        }
        
        //GD.Print("marching cubes made valid mesh");
        
        ArrayMesh arrayMesh = new ArrayMesh();
        Godot.Collections.Array arrays = [];
        arrays.Resize((int)Mesh.ArrayType.Max);
        arrays[(int)Mesh.ArrayType.Vertex] = vertices;
        arrays[(int)Mesh.ArrayType.Normal] = normals;
        
        arrayMesh.AddSurfaceFromArrays(Mesh.PrimitiveType.Triangles, arrays);
        Mesh = arrayMesh;
    }

    
    public void Load()
    {
        // TODO: load from disk if already generated (try loading path.json or smt)
        //else:
        Generate();
    }

    
    public void Unload()
    {
        QueueFree();
        // TODO: save data to disk
    }

    
    public int GridToIDX(int x, int y, int z)
    {
        return x + y * size + z * size * size;
    }

    
    public void PopulateData()
    {
        bool hasFilled = false;
        bool hasEmpty = false;

        Random rnd = new Random();
        
        for(int x = 0; x < size; x++)
        for(int y = 0; y < size; y++)
        for (int z = 0; z < size; z++)
        {
            Vector3 wPos = chunkPos + new Vector3(x, y, z);

            int cell = tgen.CellIDFromNormal(wPos.Normalized(), cellID);
            
            float height = tgen.planetRadius + tgen.heights[cell] * tgen.terrainHeight;

            float density = height - wPos.Length();
            //density = rnd.Next(-1, 10) / 10.0f;

            data[GridToIDX(x, y, z)] = density;

            if (density < 0) hasFilled = true;
            if (density > 0) hasEmpty = true;
        }

        chunkEmpty = !(hasEmpty && hasFilled);
    }
    
}
