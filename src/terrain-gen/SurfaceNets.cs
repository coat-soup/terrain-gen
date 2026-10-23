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
        public Vector4[] materials; // (4 materials, first 16bits = material ID second 16bits = material weight)

        public MeshData(Vector3[] v, Vector3[] n, Vector4[] m)
        {
            vertices = v;
            normals = n;
            materials = m;
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
    
    public static MeshData Generate(float[] data, uint[] material_data, Vector3I size, float cellSize = 1.0f)
    {
        List<Vector3> verts = new List<Vector3>();
        List<Vector3> norms = new List<Vector3>();
        List<Vector4> colours = new List<Vector4>();
		
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

                //Vector3[] quad_norms =
                //[
                    //get_surface_gradient(data, samplePoint1 + QUAD_POINTS[i][0], sample_grid_array(data, samplePoint1 + QUAD_POINTS[i][0], size), size),
                    //get_surface_gradient(data, samplePoint1 + QUAD_POINTS[i][1], sample_grid_array(data, samplePoint1 + QUAD_POINTS[i][1], size), size),
                    //get_surface_gradient(data, samplePoint1 + QUAD_POINTS[i][2], sample_grid_array(data, samplePoint1 + QUAD_POINTS[i][2], size), size),
                    //get_surface_gradient(data, samplePoint1 + QUAD_POINTS[i][3], sample_grid_array(data, samplePoint1 + QUAD_POINTS[i][3], size), size)
                //];

                Vector4[] quad_colors =
                [
                    get_material_weights(material_data, samplePoint1 + QUAD_POINTS[i][0], size),
                    get_material_weights(material_data, samplePoint1 + QUAD_POINTS[i][1], size),
                    get_material_weights(material_data, samplePoint1 + QUAD_POINTS[i][2], size),
                    get_material_weights(material_data, samplePoint1 + QUAD_POINTS[i][3], size)
                ];
                
                if (sampleVal1 < 0 && sampleVal2 >= 0)
                {
                    verts.Add(quad_points[0]);
                    verts.Add(quad_points[1]);
                    verts.Add(quad_points[2]);
                    //norms.Add(quad_norms[0]);
                    //norms.Add(quad_norms[1]);
                    //norms.Add(quad_norms[2]);
                    colours.Add(quad_colors[0]);
                    colours.Add(quad_colors[1]);
                    colours.Add(quad_colors[2]);
                    
                    verts.Add(quad_points[0]);
                    verts.Add(quad_points[2]);
                    verts.Add(quad_points[3]);
                    //norms.Add(quad_norms[0]);
                    //norms.Add(quad_norms[2]);
                    //norms.Add(quad_norms[3]);
                    colours.Add(quad_colors[0]);
                    colours.Add(quad_colors[2]);
                    colours.Add(quad_colors[3]);
                }
                else if (sampleVal1 >= 0 && sampleVal2 < 0)
                {
                    verts.Add(quad_points[0]);
                    verts.Add(quad_points[2]);
                    verts.Add(quad_points[1]);
                    //norms.Add(quad_norms[0]);
                    //norms.Add(quad_norms[2]);
                    //norms.Add(quad_norms[1]);
                    colours.Add(quad_colors[0]);
                    colours.Add(quad_colors[2]);
                    colours.Add(quad_colors[1]);
                    
                    verts.Add(quad_points[0]);
                    verts.Add(quad_points[3]);
                    verts.Add(quad_points[2]);
                    //norms.Add(quad_norms[0]);
                    //norms.Add(quad_norms[3]);
                    //norms.Add(quad_norms[2]);
                    colours.Add(quad_colors[0]);
                    colours.Add(quad_colors[3]);
                    colours.Add(quad_colors[2]);
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

    public static uint sample_grid_array(uint[] data, Vector3I pos, Vector3I size)
    {
        return sample_grid_array(data, pos.X, pos.Y, pos.Z, size);
    }
    
    public static uint sample_grid_array(uint[] data, int x, int y, int z, Vector3I size){
        if(x < 0 || y < 0 || z < 0 || x >= size.X || y >= size.Y || z >= size.Z) return 0;
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

    private struct MaterialWeightPair
    {
        public uint material;
        public float weight;

        public MaterialWeightPair(uint m, float w)
        {
            material = m;
            weight = w;
        }
    }
    
    
    public static Vector4 get_material_weights(uint[] material_data, Vector3I pos, Vector3I size)
    {
        uint[] materials = 
        [
            sample_grid_array(material_data, pos, size),
            sample_grid_array(material_data, pos + AXIS[0], size),
            sample_grid_array(material_data, pos + AXIS[1], size),
            sample_grid_array(material_data, pos + -AXIS[2], size),
        ];
        
        int other = 0;
        int other2 = 0;
        int other3 = 0;
        for (int i = 1; i < 4; i++)
            if (materials[i] != materials[0] && materials[i] != 0)
            {
                if (other == 0) other = i;
                if (other2 == 0) other2 = i;
                if (other3 == 0) other3 = i;
            }

        return new Vector4(
            PackMaterial(materials[0],  other==0f? 1f : 0f),
            PackMaterial(materials[other], other==0f? 0f : other2==0? 1f : other3==0? 0.5f : 0.33f),
            PackMaterial(materials[other2], other==0f? 0f : other2==0? 0.0f : other3==0? 0.5f : 0.33f),
            PackMaterial(materials[other3], other==0f? 0f : other2==0? 0.0f : other3==0? 0.0f : 0.33f)
        );

    }
    
    public static Vector4 get_material_weights_fancy_and_smart(uint[] material_data, Vector3I pos, Vector3I size)
    {
        List<MaterialWeightPair> materials = new List<MaterialWeightPair>();

        materials.Add(new MaterialWeightPair(sample_grid_array(material_data, pos, size), 1));
        if (materials[0].material == 0u) return Vector4.Zero;
        
        for (int i = 0; i < 3; i++)
        {
            uint material = sample_grid_array(material_data, pos + AXIS[i], size);
            if(material == 0) continue; // 0 is air;
            bool new_material = true;
            for (int j = 0; j < materials.Count; j++)
            {
                if (materials[j].material == material)
                {
                    new_material = false;
                    materials[j] = new MaterialWeightPair(material, materials[j].weight + 1);
                    break;
                }
            }
            if(new_material) materials.Add(new MaterialWeightPair(material, 1));
        }

        materials.Sort(delegate(MaterialWeightPair a, MaterialWeightPair b) { return a.weight.CompareTo(b.weight); });
        Vector4 material_weights = new Vector4(PackMaterial(materials[0].material,-100f), PackMaterial(materials[0].material,-100f),PackMaterial(materials[0].material,-100f),PackMaterial(materials[0].material,-100f));
        for (int i = 0; i < 4 && i < materials.Count; i++)
        {
            material_weights[i] = PackMaterial(materials[i].material, 1f / materials.Count);
        }

        return new Vector4(
            PackMaterial(materials[0].material, materials.Count>1? 0.5f : 1f),
            materials.Count>1? PackMaterial(materials[1].material, 0.5f) : PackMaterial(0u,0 ),
            PackMaterial(0u, 0),
            PackMaterial(0u, 0)
        );

        return material_weights;
    }
    
    
    static float PackMaterial(uint materialId, float weight)
    {
        if (materialId > ushort.MaxValue)
            throw new ArgumentOutOfRangeException(nameof(materialId));

        // Convert weight to IEEE 754 half-precision bits.
        ushort weightBits = BitConverter.HalfToUInt16Bits((Half)weight);

        // Upper 16 bits = ID, lower 16 bits = weight.
        uint packed = (materialId << 16) | weightBits;

        // Reinterpret all 32 bits as a float.
        return BitConverter.UInt32BitsToSingle(packed);
    }
}
