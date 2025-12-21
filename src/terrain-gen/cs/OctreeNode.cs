using Godot;
using System;

public partial class OctreeNode : RefCounted
{
    public Vector3 position;
    public float sideLength;
    public int depth;
    public OctreeNode[] children;
    public int size;
    public int cell_id;
    public TerrainChunk chunk;
    
    
    public OctreeNode(Vector3 pos, float length, int d, int s, int c_id)
    {
        position = pos;
        sideLength = length;
        depth = d;
        size = s;
        cell_id = c_id;
    }
}
