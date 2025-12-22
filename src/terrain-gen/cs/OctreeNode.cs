using Godot;
using System;

public partial class OctreeNode : RefCounted
{
    public Vector3 position;
    public float sideLength;
    public int depth;
    public OctreeNode[] children;
    public OctreeNode parent;
    public int size;
    public int cell_id;
    public TerrainChunk chunk;
    public bool childLoaded;
    public bool queuedForKill = false;
    
    
    public OctreeNode(Vector3 pos, float length, int d, int s, int c_id, OctreeNode par = null)
    {
        position = pos;
        sideLength = length;
        depth = d;
        size = s;
        cell_id = c_id;
        parent = par;
    }

    
    public void SetLoaded(bool value)
    {
        childLoaded = value;
        
        if (value)
        {
            if(parent != null) parent.SetLoaded(true);
        }
        else if (parent != null)
        {
            foreach (OctreeNode child in parent.children)
            {
                if (child.childLoaded) return;
            }
            parent.SetLoaded(false);
        }
    }
}
