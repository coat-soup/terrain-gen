using Godot;
using System;
using System.Collections.Generic;
//using Godot.Collections;


public struct MCData
{
	public Vector3[] vertices;
	public Vector3[] normals;
	public Color[] colours;

	public MCData(Vector3[] v, Vector3[] n, Color[] c)
	{
		vertices = v;
		normals = n;
		colours = c;
	}
}


public partial class MarchingCubes : Node
{
	public static Vector3 Interpolate(Vector3 p1, Vector3 p2, float v1, float v2, float iso)
	{
		if (Mathf.Abs(iso - v1) < 0.00001f)
			return p1;
		
		if (Mathf.Abs(iso - v2) < 0.00001f)
			return p2;
		
		if (Mathf.Abs(v1 - v2) < 0.00001f)
			return p1;
		
		float t = (iso - v1) / (v2 - v1);
		return p1 + t * (p2 - p1);
	}
	
	public float DummyFunction(){
		return 5.0f;
	}
	
	public void DummyDummyFunction(){
		//do nothing
	}
	
	
	public static MCData Generate(float[] data, uint[] materialData, float maxMaterialID, Vector3I size, float iso = 0.0f, float cellSize = 1.0f)
	{
		List<Vector3> verts = new List<Vector3>();
		List<Vector3> norms = new List<Vector3>();
		List<Color> colours = new List<Color>();
		
		for (int x = 0; x < size.X - 1; x++)
			for (int y = 0; y < size.Y - 1; y++)
				for (int z = 0; z < size.Z - 1; z++)
				{
					// corner positions
					Vector3[] p = new Vector3[]
					{
						new Vector3(x,     y,     z    ) * cellSize,
						new Vector3(x + 1, y,     z    ) * cellSize,
						new Vector3(x + 1, y,     z + 1) * cellSize,
						new Vector3(x,     y,     z + 1) * cellSize,
						new Vector3(x,     y + 1, z    ) * cellSize,
						new Vector3(x + 1, y + 1, z    ) * cellSize,
						new Vector3(x + 1, y + 1, z + 1) * cellSize,
						new Vector3(x,     y + 1, z + 1) * cellSize
					};
					
					// data values
					float[] val = new float[]
					{
						sample_grid_array(data, x,     y,     z, size),
						sample_grid_array(data, x + 1, y,     z, size),
						sample_grid_array(data, x + 1, y,     z + 1, size),
						sample_grid_array(data, x,     y,     z + 1, size),
						sample_grid_array(data, x,     y + 1, z, size),
						sample_grid_array(data, x + 1, y + 1, z, size),
						sample_grid_array(data, x + 1, y + 1, z + 1, size),
						sample_grid_array(data, x,     y + 1, z + 1, size)
					};
					
					// normals
					Vector3[] n = new Vector3[]
					{
						GetVoxelGradient(data, x,     y,     z, size),
						GetVoxelGradient(data, x + 1, y,     z, size),
						GetVoxelGradient(data, x + 1, y,     z + 1, size),
						GetVoxelGradient(data, x,     y,     z + 1, size),
						GetVoxelGradient(data, x,     y + 1, z, size),
						GetVoxelGradient(data, x + 1, y + 1, z, size),
						GetVoxelGradient(data, x + 1, y + 1, z + 1, size),
						GetVoxelGradient(data, x,     y + 1, z + 1, size)
					};
					
					// cube index
					int cubeIndex = 0;
					for (int i = 0; i < 8; i++)
					{
						if (val[i] < iso)
							cubeIndex |= (1 << i);
					}
					
					int edgeMask = MarchingCubesTables.EDGE_TABLE[cubeIndex];
					if (edgeMask == 0)
						continue;
					
					Vector3[] edgeVert = new Vector3[12];
					Vector3[] edgeNorm = new Vector3[12];
					
					int[,] edgePts = new int[,]
					{
						{0,1},{1,2},{2,3},{3,0},
						{4,5},{5,6},{6,7},{7,4},
						{0,4},{1,5},{2,6},{3,7}
					};
					
					for (int e = 0; e < 12; e++)
					{
						if ((edgeMask & (1 << e)) != 0)
						{
							int a = edgePts[e, 0];
							int b = edgePts[e, 1];
							edgeVert[e] = Interpolate(p[a], p[b], val[a], val[b], iso);
							edgeNorm[e] = Interpolate(n[a], n[b], val[a], val[b], iso);
						}
					}
					
					int[] triList = MarchingCubesTables.TRI_TABLE[cubeIndex];
					int idx = 0;
					
					while (triList[idx] != -1)
					{
						verts.Add(edgeVert[triList[idx]]);
						verts.Add(edgeVert[triList[idx + 1]]);
						verts.Add(edgeVert[triList[idx + 2]]);
						
						norms.Add(edgeNorm[triList[idx]]);
						norms.Add(edgeNorm[triList[idx + 1]]);
						norms.Add(edgeNorm[triList[idx + 2]]);

						Color c = new Color(sample_material_array(materialData, x, y, z, size) / maxMaterialID, 0, 0);
						colours.Add(c);
						colours.Add(c);
						colours.Add(c);
						
						idx += 3;
					}
				}

		return new MCData(verts.ToArray(), norms.ToArray(), colours.ToArray());
	}

	public static float sample_grid_array(float[] data, int x, int y, int z, Vector3I size){
		if(x < 0 || y < 0 || z < 0 || x >= size.X || y >= size.Y || z >= size.Z) return -1.0f;
		int index = x + y * size.X + z * size.X * size.Y;
		return data[index];
	}
	
	public static uint sample_material_array(uint[] data, int x, int y, int z, Vector3I size){
		if(x < 0 || y < 0 || z < 0 || x >= size.X || y >= size.Y || z >= size.Z) return 0;
		int index = x + y * size.X + z * size.X * size.Y;
		return data[index];
	}

	public static Vector3 GetVoxelGradient(float[] data, int x, int y, int z, Vector3I grid_size) {
		float dx = sample_grid_array(data, x + 1, y, z, grid_size) - sample_grid_array(data, x - 1, y, z, grid_size);
		float dy = sample_grid_array(data, x, y + 1, z, grid_size) - sample_grid_array(data, x, y - 1, z, grid_size);
		float dz = sample_grid_array(data, x, y, z + 1, grid_size) - sample_grid_array(data, x, y, z - 1, grid_size);
		
		return new Vector3(dx, dy, dz).Normalized() * -1.0f;
	}
}
