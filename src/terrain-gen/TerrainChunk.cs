using Godot;
using System;

public partial class TerrainChunk : Node3D
{
    public ChunkManager chunkManager;
    public Vector3I chunkPos;
    public int chunkSize;
    public float[] data;
    public uint[] material_data;

    public TerrainChunk(ChunkManager manager, Vector3I pos, int size)
    {
        chunkManager = manager;
        chunkPos = pos;
        chunkSize = size + 3; // padding for seams
    }
    
    public void LoadChunk()
    {
        PopulateData();
        GenerateMesh();
    }

    void GenerateMesh()
    {
        SurfaceNets.MeshData meshData = SurfaceNets.Generate(data, material_data, new Vector3I(chunkSize,chunkSize,chunkSize));
        
        SurfaceTool st = new SurfaceTool();
        st.Begin(Mesh.PrimitiveType.Triangles);
        st.SetCustomFormat(0, SurfaceTool.CustomFormat.RgbaFloat);
        for(int i = 0; i < meshData.vertices.Length; i++)
        {
            st.SetCustom(0, new Color(meshData.materials[i].X, meshData.materials[i].Y, meshData.materials[i].Z, meshData.materials[i].W));
            st.AddVertex(meshData.vertices[i]);
        }
        st.GenerateNormals();
        st.SetMaterial(chunkManager.material);
        
        
        GD.Print(meshData.vertices.Length + " verts:");

        MeshInstance3D meshInstance = new MeshInstance3D();
        AddChild(meshInstance);
        
        meshInstance.Mesh = st.Commit();
    }
    
    void PopulateData()
    {
        data = new float[chunkSize * chunkSize * chunkSize];
        material_data = new uint[chunkSize * chunkSize * chunkSize];
        for (int x = 0; x < chunkSize - 1; x++) for (int y = 0; y < chunkSize - 1; y++) for (int z = 0; z < chunkSize - 1; z++)
        {
            //data[x + y * size.X + z * size.X * size.Y] = (new Vector3(x, y, z) - new Vector3(size.X / 2, size.Y / 2, size.Z / 2)).Length() - 30f;
            data[x + y * chunkSize + z * chunkSize * chunkSize] = chunkManager.noise.GetNoise3Dv(new Vector3(x, y, z) + chunkPos*chunkManager.chunkSize);
            
            float height = (chunkManager.noise.GetNoise2Dv(new Vector2(x, z) + new Vector2(chunkPos.X, chunkPos.Z) * chunkManager.chunkSize) + 1f) * 50f;
            data[x + y * chunkSize + z * chunkSize * chunkSize] = chunkPos.Y*chunkManager.chunkSize + y - height;

            // 0 is air
            material_data[x + y * chunkSize + z * chunkSize * chunkSize] = y > chunkSize / 2 ? (z > chunkSize / 2? (x > chunkSize/2? 1u : 2u) : (x > chunkSize/2? 3u : 4u)) : (z > chunkSize / 2? (x > chunkSize/2? 5u : 6u) : (x > chunkSize/2? 7u : 8u));
        }
    }
}
