using Godot;
using System;

public partial class TerrainChunk : Node3D
{
    public ChunkManager chunkManager;
    public Vector3I chunkPos;
    public int chunkSize;
    public float[] data;
    public uint[] material_data;

    private int realSize;
    private int voxelSize;
    
    MeshInstance3D meshInstance;

    public bool dirty = true;

    public bool debug_bounds = true;

    public int chunkLOD = 0;
    public TerrainChunk parentChunk;
    public TerrainChunk[] childChunks;

    private static Color[] debugBoundLODColours = new[] { Colors.GreenYellow,  Colors.Orange, Colors.DeepSkyBlue, Colors.Red};
    
    public TerrainChunk(ChunkManager manager, Vector3I pos, int size, int lod, TerrainChunk parent = null)
    {
        chunkManager = manager;
        chunkPos = pos;
        chunkSize = size + 3; // padding for seams
        chunkLOD = lod;
        parentChunk = parent;

        voxelSize = (int)Mathf.Pow(2, chunkLOD);
        realSize = chunkManager.chunkSize * voxelSize;
    }

    public override void _Process(double delta)
    {
        base._Process(delta);
        if (debug_bounds && childChunks == null)
        {
            DebugDraw3D.ScopedConfig().SetThickness(1);
            DebugDraw3D.DrawBox(GlobalPosition, Quaternion.Identity, Vector3.One * realSize, debugBoundLODColours[chunkLOD % debugBoundLODColours.Length]);
        }
    }

    public void LoadChunk()
    {
        if (childChunks != null)
        {
            foreach (TerrainChunk chunk in childChunks) chunk.LoadChunk();
        }
        else
        {
            PopulateData();
            GenerateMesh();
        }
        
        dirty = false;
    }

    void GenerateMesh()
    {
        GD.Print("Generating chunk at " + chunkPos);
        double time = Time.GetUnixTimeFromSystem();
        double ttime = Time.GetUnixTimeFromSystem();
        
        SurfaceNets.MeshData meshData = SurfaceNets.Generate(data, material_data, new Vector3I(chunkSize,chunkSize,chunkSize), voxelSize);
        
        GD.Print("surface nets: " + (Time.GetUnixTimeFromSystem() - time) + "s");
        time = Time.GetUnixTimeFromSystem();
        
        SurfaceTool st = new SurfaceTool();
        st.Begin(Mesh.PrimitiveType.Triangles);
        st.SetCustomFormat(0, SurfaceTool.CustomFormat.RgbaFloat);
        for(int i = 0; i < meshData.vertices.Length; i++)
        {
            st.SetCustom(0, new Color(meshData.materials[i].X, meshData.materials[i].Y, meshData.materials[i].Z, meshData.materials[i].W));
            st.AddVertex(meshData.vertices[i]);
        }
        
        GD.Print("vertex data: " + (Time.GetUnixTimeFromSystem() - time) + "s");
        time = Time.GetUnixTimeFromSystem();
        
        st.GenerateNormals();
        GD.Print("normal data: " + (Time.GetUnixTimeFromSystem() - time) + "s");
        
        st.SetMaterial(chunkManager.material);
        
        
        GD.Print(meshData.vertices.Length + " verts:");

        if (meshInstance == null)
        {
            meshInstance = new MeshInstance3D();
            Callable.From(() => { AddChild(meshInstance); }).CallDeferred();
        }
        
        //meshInstance.Mesh = st.Commit();
        Callable.From(() => { meshInstance.Mesh = st.Commit(); }).CallDeferred();
        
        GD.Print("chunk finished in : " + (Time.GetUnixTimeFromSystem() - ttime) + "s\n");
    }
    
    void PopulateData()
    {
        data = new float[chunkSize * chunkSize * chunkSize];
        material_data = new uint[chunkSize * chunkSize * chunkSize];
        for (int x = 0; x < chunkSize - 1; x++) for (int y = 0; y < chunkSize - 1; y++) for (int z = 0; z < chunkSize - 1; z++)
        {
            //data[x + y * chunkSize + z * chunkSize * chunkSize] = (new Vector3(x, y, z) - Vector3I.One*chunkSize/2).Length() - 30f;
            //data[x + y * chunkSize + z * chunkSize * chunkSize] = chunkManager.noise.GetNoise3Dv(new Vector3(x, y, z) + chunkPos*realSize);
            
            float height = (chunkManager.noise.GetNoise2Dv(new Vector2(x, z) * voxelSize + new Vector2(chunkPos.X, chunkPos.Z) * chunkManager.chunkSize) + 1f)/2f * 100f;
            data[x + y * chunkSize + z * chunkSize * chunkSize] = chunkPos.Y*chunkManager.chunkSize + y*voxelSize - height;

            // 0 is air
            material_data[x + y * chunkSize + z * chunkSize * chunkSize] = y > chunkSize / 2 ? (z > chunkSize / 2? (x > chunkSize/2? 1u : 2u) : (x > chunkSize/2? 3u : 4u)) : (z > chunkSize / 2? (x > chunkSize/2? 5u : 6u) : (x > chunkSize/2? 7u : 8u));
        }
    }

    public bool IsPointInBounds(Vector3 point)
    {
        return point.X > GlobalPosition.X && point.Y > GlobalPosition.Y && point.Z > GlobalPosition.Z
            && point.X < GlobalPosition.X + realSize && point.Y < GlobalPosition.Y + realSize && point.Z < GlobalPosition.Z + realSize;
    }
}
