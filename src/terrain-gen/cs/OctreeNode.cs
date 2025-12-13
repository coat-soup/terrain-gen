using Godot;
using System;

public partial class OctreeNode : Node
{
    public Vector3 position;
    public float sideLength;
    public int depth;
    public OctreeNode[] children;
    public int size;

    
    public OctreeNode(Vector3 pos, float length, int d, int s)
    {
        position = pos;
        sideLength = length;
        depth = d;
        size = s;
        children = [];
    }
}
