using Godot;
using System;

public partial class OctreeNode : Node
{
    public Vector3 position;
    public float sideLength;
    public int depth;
    public OctreeNode[] children;
    public int size;
    public int cell_id;

    
    public OctreeNode(Vector3 pos, float length, int d, int s, int c_id)
    {
        position = pos;
        sideLength = length;
        depth = d;
        size = s;
        children = [];
        cell_id = c_id;
    }
}
