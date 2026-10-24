using Godot;
using System;

public partial class SurfaceNetsScene : Node3D
{
    [Export] public Vector3I size = new Vector3I(20,20,20);
    [Export] public MeshInstance3D mesh;
    [Export] public FastNoiseLite noise;

    [Export] public ShaderMaterial material;
    
    public override void _Ready()
    {
        base._Ready();

        //GetViewport().DebugDraw = Viewport.DebugDrawEnum.Wireframe;
        
        GenerateMeshST();
    }

    public override void _Input(InputEvent @event)
    {
        base._Input(@event);

        if (Input.IsActionJustPressed("debug_reload"))
        {
            double time = Time.GetUnixTimeFromSystem();
            GenerateMeshST();
            GD.Print("Generated in " + (Time.GetUnixTimeFromSystem() - time) + " seconds.");
        }
        
    }

    public void GenerateMesh()
    {
        noise.Seed = Random.Shared.Next();
        
        float[] data = new float[size.X * size.Y * size.Z];
        uint[] material_data = new uint[size.X * size.Y * size.Z];
        for (int x = 0; x < size.X - 1; x++) for (int y = 0; y < size.Y - 1; y++) for (int z = 0; z < size.Z - 1; z++)
        {
            //data[x + y * size.X + z * size.X * size.Y] = (new Vector3(x, y, z) - new Vector3(size.X / 2, size.Y / 2, size.Z / 2)).Length() - 30f;
            data[x + y * size.X + z * size.X * size.Y] = noise.GetNoise3D(x, y, z);
        }
        
        SurfaceNets.MeshData meshData = SurfaceNets.Generate(data, material_data, size);

        ArrayMesh arrayMesh = new ArrayMesh();
        Godot.Collections.Array arrays = [];
        arrays.Resize((int)Mesh.ArrayType.Max);
        arrays[(int)Mesh.ArrayType.Vertex] = meshData.vertices;
        //arrays[(int)Mesh.ArrayType.Normal] = meshData.normals;
        //arrays[(int)Mesh.ArrayType.Color] = meshData.colours;
        
        GD.Print(meshData.vertices.Length + " verts:");
        
        arrayMesh.AddSurfaceFromArrays(Mesh.PrimitiveType.Triangles, arrays);

        mesh.Mesh = arrayMesh;
    }
    
    public void GenerateMeshST()
    {
        noise.Seed = Random.Shared.Next();
        
        float[] data = new float[size.X * size.Y * size.Z];
        uint[] material_data = new uint[size.X * size.Y * size.Z];
        for (int x = 0; x < size.X - 1; x++) for (int y = 0; y < size.Y - 1; y++) for (int z = 0; z < size.Z - 1; z++)
        {
            //data[x + y * size.X + z * size.X * size.Y] = (new Vector3(x, y, z) - new Vector3(size.X / 2, size.Y / 2, size.Z / 2)).Length() - 30f;
            data[x + y * size.X + z * size.X * size.Y] = noise.GetNoise3D(x, y, z);

            // 0 is air
            material_data[x + y * size.X + z * size.X * size.Y] = y > size.Y / 2 ? (z > size.Z / 2? (x > size.X/2? 1u : 2u) : (x > size.X/2? 3u : 4u)) : (z > size.Z / 2? (x > size.X/2? 5u : 6u) : (x > size.X/2? 7u : 8u));
        }
        
        SurfaceNets.MeshData meshData = SurfaceNets.Generate(data, material_data, size);
        
        SurfaceTool st = new SurfaceTool();
        st.Begin(Mesh.PrimitiveType.Triangles);
        st.SetCustomFormat(0, SurfaceTool.CustomFormat.RgbaFloat);
        for(int i = 0; i < meshData.vertices.Length; i++)
        {
            st.SetCustom(0, new Color(meshData.materials[i].X, meshData.materials[i].Y, meshData.materials[i].Z, meshData.materials[i].W));
            st.AddVertex(meshData.vertices[i]);
        }
        st.GenerateNormals();
        st.SetMaterial(material);
        
        
        GD.Print(meshData.vertices.Length + " verts:");

        mesh.Mesh = st.Commit();
    }
    
    
}
