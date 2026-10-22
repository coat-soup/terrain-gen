using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using Range = Godot.Range;

public partial class SurfaceNets
{
    public struct MeshData
    {
        public Vector3[] vertices;
        public Vector3[] normals;
        public Color[] colours;

        public MeshData(Vector3[] v, Vector3[] n, Color[] c)
        {
            vertices = v;
            normals = n;
            colours = c;
        }
    }

    
    static Vector3I[] AXIS = [
        new(1,0,0), 
        new(0,1,0), 
        new(0,0,1)
    ];
    
    static Vector3I[][] QUAD_POINTS = [

    [
        new Vector3I( 0, 0,-1),
        new Vector3I( 0,-1,-1),
        new Vector3I( 0,-1, 0),
        new Vector3I( 0, 0, 0)
    ], 

    [
        new Vector3I( 0, 0,-1),
        new Vector3I( 0, 0, 0),
        new Vector3I(-1, 0, 0),
        new Vector3I(-1, 0,-1)
    ], 

    [
        new Vector3I( 0, 0, 0),
        new Vector3I( 0,-1, 0),
        new Vector3I(-1,-1, 0),
        new Vector3I(-1, 0, 0)
    ], 
    ];

    private static Vector3I[][] EDGES =
    [
        // Edges on min Z axis
        [new Vector3I(0, 0, 0), new Vector3I(1, 0, 0)],
        [new Vector3I(1, 0, 0), new Vector3I(1, 1, 0)],
        [new Vector3I(1, 1, 0), new Vector3I(0, 1, 0)],
        [new Vector3I(0, 1, 0), new Vector3I(0, 0, 0)],
        // Edges on max Z axis
        [new Vector3I(0, 0, 1), new Vector3I(1, 0, 1)],
        [new Vector3I(1, 0, 1), new Vector3I(1, 1, 1)],
        [new Vector3I(1, 1, 1), new Vector3I(0, 1, 1)],
        [new Vector3I(0, 1, 1), new Vector3I(0, 0, 1)],
        // Edges connecting min Z to max Z
        [new Vector3I(0, 0, 0), new Vector3I(0, 0, 1)],
        [new Vector3I(1, 0, 0), new Vector3I(1, 0, 1)],
        [new Vector3I(1, 1, 0), new Vector3I(1, 1, 1)],
        [new Vector3I(0, 1, 0), new Vector3I(0, 1, 1)],
    ];
    
    public static MeshData Generate(float[] data, Vector3I size, float iso = 0.0f, float cellSize = 1.0f)
    {
        List<Vector3> verts = new List<Vector3>();
        List<Vector3> norms = new List<Vector3>();
        List<Color> colours = new List<Color>();
		
        for (int x = 0; x < size.X - 1; x++) for (int y = 0; y < size.Y - 1; y++) for (int z = 0; z < size.Z - 1; z++)
        {
            for (int i = 0; i < 3; i++)
            {
                Vector3I axis = AXIS[i];
                Vector3I samplePoint1 = new Vector3I(x, y, z);
                Vector3I samplePoint2 = new Vector3I(x, y, z) + axis;
                float sampleVal1 = sample_grid_array(data, samplePoint1.X, samplePoint1.Y, samplePoint1.Z, size);
                float sampleVal2 = sample_grid_array(data, samplePoint2.X, samplePoint2.Y, samplePoint2.Z, size);

                if (Mathf.Sign(sampleVal1) == Mathf.Sign(sampleVal2)) continue;
                
                Vector3[] quad_points =
                [
                    interpolate_vertex_position(data, samplePoint1 + QUAD_POINTS[i][0], size),
                    interpolate_vertex_position(data, samplePoint1 + QUAD_POINTS[i][1], size),
                    interpolate_vertex_position(data, samplePoint1 + QUAD_POINTS[i][2], size),
                    interpolate_vertex_position(data, samplePoint1 + QUAD_POINTS[i][3], size)
                ];

                Vector3[] quad_norms =
                [
                    get_surface_gradient(data, samplePoint1 + QUAD_POINTS[i][0], sample_grid_array(data, samplePoint1 + QUAD_POINTS[i][0], size), size),
                    get_surface_gradient(data, samplePoint1 + QUAD_POINTS[i][1], sample_grid_array(data, samplePoint1 + QUAD_POINTS[i][1], size), size),
                    get_surface_gradient(data, samplePoint1 + QUAD_POINTS[i][2], sample_grid_array(data, samplePoint1 + QUAD_POINTS[i][2], size), size),
                    get_surface_gradient(data, samplePoint1 + QUAD_POINTS[i][3], sample_grid_array(data, samplePoint1 + QUAD_POINTS[i][3], size), size)
                ];

                if (sampleVal1 < 0 && sampleVal2 >= 0)
                {
                    verts.Add(quad_points[0]);
                    verts.Add(quad_points[1]);
                    verts.Add(quad_points[2]);
                    norms.Add(quad_norms[0]);
                    norms.Add(quad_norms[1]);
                    norms.Add(quad_norms[2]);
                    
                    verts.Add(quad_points[0]);
                    verts.Add(quad_points[2]);
                    verts.Add(quad_points[3]);
                    norms.Add(quad_norms[0]);
                    norms.Add(quad_norms[2]);
                    norms.Add(quad_norms[3]);
                }
                else if (sampleVal1 >= 0 && sampleVal2 < 0)
                {
                    verts.Add(quad_points[0]);
                    verts.Add(quad_points[2]);
                    verts.Add(quad_points[1]);
                    norms.Add(quad_norms[0]);
                    norms.Add(quad_norms[2]);
                    norms.Add(quad_norms[1]);
                    
                    verts.Add(quad_points[0]);
                    verts.Add(quad_points[3]);
                    verts.Add(quad_points[2]);
                    norms.Add(quad_norms[0]);
                    norms.Add(quad_norms[3]);
                    norms.Add(quad_norms[2]);
                }
            }
        }

        return new MeshData(verts.ToArray(), norms.ToArray(), colours.ToArray());
    }

    public static float sample_grid_array(float[] data, Vector3I pos, Vector3I size)
    {
        return sample_grid_array(data, pos.X, pos.Y, pos.Z, size);
    }
    
    public static float sample_grid_array(float[] data, int x, int y, int z, Vector3I size){
        if(x < 0 || y < 0 || z < 0 || x >= size.X || y >= size.Y || z >= size.Z) return -1.0f;
        int index = x + y * size.X + z * size.X * size.Y;
        return data[index];
    }

    public static Vector3 interpolate_vertex_position(float[] data, Vector3I pos, Vector3I data_size)
    {
        Vector3 total = Vector3.Zero;
        int surfaceEdgeCount = 0;

        for (int i = 0; i < 12; i++)
        {
            Vector3I point1 = pos + EDGES[i][0];
            Vector3I point2 = pos + EDGES[i][1];
            float val1 = sample_grid_array(data, point1.X, point1.Y, point1.Z, data_size);
            float val2 = sample_grid_array(data, point2.X, point2.Y, point2.Z, data_size);

            if (Mathf.Sign(val1) != Mathf.Sign(val2))
            {
                surfaceEdgeCount++;
                total += new Vector3(point1.X, point1.Y, point1.Z).Lerp(new Vector3(point2.X, point2.Y, point2.Z), Mathf.Abs(val1) / (Mathf.Abs(val1) + Mathf.Abs(val2)));
            }
        }
        if (surfaceEdgeCount == 0) return new Vector3(pos.X, pos.Y, pos.Z) + Vector3.One * 0.5f;
        return total / surfaceEdgeCount;
    }

    public static Vector3 get_surface_gradient(float[] data, Vector3I pos, float sample_value, Vector3I data_size)
    {
        return new Vector3(
            sample_grid_array(data, pos + AXIS[0], data_size) - sample_value,
            sample_grid_array(data, pos + AXIS[1], data_size) - sample_value,
            sample_grid_array(data, pos + AXIS[2], data_size) - sample_value
            ).Normalized();
    }
}
