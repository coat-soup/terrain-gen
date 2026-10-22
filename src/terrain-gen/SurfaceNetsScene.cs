using Godot;
using System;

public partial class SurfaceNetsScene : Node3D
{
    [Export] public Vector3I size = new Vector3I(20,20,20);
    [Export] public MeshInstance3D mesh;
    [Export] public FastNoiseLite noise;
    
    public override void _Ready()
    {
        base._Ready();

        //GetViewport().DebugDraw = Viewport.DebugDrawEnum.Wireframe;
        
        float[] data = new float[size.X * size.Y * size.Z];
        for (int x = 0; x < size.X - 1; x++) for (int y = 0; y < size.Y - 1; y++) for (int z = 0; z < size.Z - 1; z++)
        {
            //data[x + y * size.X + z * size.X * size.Y] = (new Vector3(x, y, z) - new Vector3(size.X / 2, size.Y / 2, size.Z / 2)).Length() - 5f;
            data[x + y * size.X + z * size.X * size.Y] = noise.GetNoise3D(x, y, z);
        }
        
        SurfaceNets.MeshData meshData = SurfaceNets.Generate(data, size);

        ArrayMesh arrayMesh = new ArrayMesh();
        Godot.Collections.Array arrays = [];
        arrays.Resize((int)Mesh.ArrayType.Max);
        arrays[(int)Mesh.ArrayType.Vertex] = meshData.vertices;
        arrays[(int)Mesh.ArrayType.Normal] = meshData.normals;
        //arrays[(int)Mesh.ArrayType.Color] = meshData.colours;
        
        GD.Print(meshData.vertices.Length + " verts:");
        
        arrayMesh.AddSurfaceFromArrays(Mesh.PrimitiveType.Triangles, arrays);

        mesh.Mesh = arrayMesh;
    }
}
