using Godot;
using System;
using System.Collections.Generic;
using Godot.Collections;


public partial class ChunkVoxelSampler : Node
{
	public static int grid_to_idx(int x, int y, int z, Vector3I size)
		=> x + size.X * (y + size.Y * z);
	
	public static float BingleBangus(Array<Array<float>> ars){
		GD.Print("JELO");
		
		return 6;
	}
	
	public static float[] PopulatePlanetData(Vector3 chunk_pos, Vector3I size, int lod_level, Vector3[] normals, float[] heights, Array<Array<int>> neighbours, int main_chunk_cell, float planet_radius, float terrain_height)
	{
		bool is_chunk_empty = true;
		
		float[] data = new float[size.X * size.Y * size.Z];
		
		for (int z = 0; z < size.Z; z++)
		{
			for (int y = 0; y < size.Y; y++)
			{
				for (int x = 0; x < size.X; x++)
				{
					int idx = grid_to_idx(x, y, z, size);
					data[idx] = 1.0f;
					
					Vector3 worldPos = chunk_pos + new Vector3(x, y, z) * Mathf.Pow(2, lod_level);
					float r = worldPos.Length();
					
					if (Mathf.IsZeroApprox(r))
					{
						data[idx] = -1.0f;
						continue;
					}
					
					Vector3 normal = worldPos.Normalized();
					
					int cell = GetPlanetCellFromNormal(normal, normals, neighbours, main_chunk_cell);
					
					float height = InterpolateValueBarycentric(normal, cell, normals, heights, neighbours);
					
					float surfaceRadius = planet_radius + height * terrain_height;
					
					float density = surfaceRadius - r;
					
					data[idx] = density;
					
					if (density > 0)
						is_chunk_empty = false;
				}
			}
		}
		if (is_chunk_empty) return new float[0];
		else return data;
	}
	
	public static int GetPlanetCellFromNormal(Vector3 normal, Vector3[] normals, Array<Array<int>> neighbours, int start_cell = 0)
	{
		int id = start_cell;
		float bestDot = normal.Dot(normals[start_cell]);
		
		while (true)
		{
			bool improved = false;
		
			foreach (int n_id in neighbours[id])
			{
				float d = normal.Dot(normals[n_id]);
				
				if (d > bestDot)
				{
					bestDot = d;
					id = n_id;
					improved = true;
					break;
				}
			}
			
			if (!improved)
				return id;
		}
	}
	
	
	public static bool PointInSphericalTriangle(Vector3 p, Vector3 a, Vector3 b, Vector3 c)
	{
		Vector3 ab = a.Cross(b);
		Vector3 bc = b.Cross(c);
		Vector3 ca = c.Cross(a);
		
		float s1 = ab.Dot(p);
		float s2 = bc.Dot(p);
		float s3 = ca.Dot(p);
		
		bool allPositive = (s1 >= 0f && s2 >= 0f && s3 >= 0f);
		bool allNegative = (s1 <= 0f && s2 <= 0f && s3 <= 0f);
		
		return allPositive || allNegative;
	}
	
	public static List<int> FindDelaunayTriangle(int closest, Vector3 p, Vector3[] normals, Array<Array<int>> neighbours)
	{
		Vector3 center = normals[closest];
		
		for (int i = 0; i < neighbours[closest].Count; i++)
		{
			int bIndex = neighbours[closest][i];
			int cIndex = neighbours[closest][(i + 1) % neighbours[closest].Count];
			
			Vector3 b = normals[bIndex];
			Vector3 c = normals[cIndex];
			
			if (PointInSphericalTriangle(p, center, b, c)) return new List<int>() { closest, bIndex, cIndex };
		}
		
		return new List<int>() { closest, neighbours[closest][0], neighbours[closest][1] };
	}
	
	public static float InterpolateValueBarycentric(Vector3 position, int closest, Vector3[] normals, float[] heights, Array<Array<int>> neighbours)
	{
		List<int> cells = FindDelaunayTriangle(closest, position, normals, neighbours);
		
		if (cells.Count < 3)
			return heights[closest];
		
		Vector3 A = normals[cells[0]];
		Vector3 B = normals[cells[1]];
		Vector3 C = normals[cells[2]];
		
		Vector3 P = position.Normalized();
		
		float areaTotal = TriArea(A, B, C);
		float areaA = TriArea(P, B, C);
		float areaB = TriArea(A, P, C);
		float areaC = TriArea(A, B, P);
		
		float wA = areaA / areaTotal;
		float wB = areaB / areaTotal;
		float wC = areaC / areaTotal;
		
		float hA = heights[cells[0]];
		float hB = heights[cells[1]];
		float hC = heights[cells[2]];
		
		return hA * wA + hB * wB + hC * wC;
	}
	
	public static float TriArea(Vector3 a, Vector3 b, Vector3 c)
	{
		return Mathf.Atan2(
			a.Dot(b.Cross(c)),
			1.0f + a.Dot(b) + b.Dot(c) + c.Dot(a)
		);
	}
}
