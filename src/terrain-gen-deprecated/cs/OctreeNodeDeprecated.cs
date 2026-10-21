using Godot;
using System;

public partial class OctreeNodeDeprecated : RefCounted
{
    public Vector3 position;
    public float sideLength;
    public int depth;
    public OctreeNodeDeprecated[] children;
    public OctreeNodeDeprecated parent;
    public int size;
    public int cell_id;
    public TerrainChunkDeprecated chunk;
    public FoliageChunkDeprecated fChunk;
    public bool chunkQueued;
    public String path;
    
    
    public OctreeNodeDeprecated(Vector3 pos, float length, int d, int s, int c_id, String p = "", OctreeNodeDeprecated par = null)
    {
        position = pos;
        sideLength = length;
        depth = d;
        size = s;
        cell_id = c_id;
        path = p;
        parent = par;
    }
}
