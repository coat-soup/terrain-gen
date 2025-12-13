using System;
using System.Linq;
using Godot;
using Godot.Collections;

public partial class TerrainGenerator : Node
{
    [Export] public float planetRadius = 12000.0f;
    [Export] public float terrainHeight = 1000.0f;
    [Export] public int chunkSize = 32;

    [Export] public int debug_tree_depth_limit = 4;
    
    private Array<Array<int>> neighbours;
    private Vector3[] positions;
    private float[] heights;
    private Vector3[] windDirs;
    private float[] precipitations;
    private int[] climateZoneIDs;
    
    OctreeNode tree;
    private int n_nodes;
    
    
    public void CreateTreeFromDataArrays(Array<Array<int>> _neighbours, Vector3[] _positions, float[] _heights, Vector3[] _windDirs, float[] _precipitations, int[] _climateZoneIDs)
    {
        neighbours = _neighbours;
        positions = _positions;
        heights = _heights;
        windDirs = _windDirs;
        precipitations = _precipitations;
        climateZoneIDs = _climateZoneIDs;
        GD.Print("Creating tree from data. Got heights size " + _heights.Length);
        
        // create root node
        float margin = terrainHeight * 1.2f;
        float diameter = 2.0f * planetRadius + 2.0f * margin;
        float s = chunkSize;
        int si = 0;
        while (s < diameter) { s *= 2.0f; si += 1;}
        Vector3 rootPos = -Vector3.One * s / 2.0f;
        tree = new OctreeNode(rootPos, s, 0, si, 0);

        double time = Time.GetUnixTimeFromSystem();
        
        GD.Print("Root node size: ", tree.size);
        n_nodes = 0;
        BuildTree(tree);
        GD.Print("Tree finished with " + n_nodes + " nodes in " + (Time.GetUnixTimeFromSystem() - time) + " seconds.");
    }

    
    public void BuildTree(OctreeNode node)
    {
        n_nodes++;
        
        node.cell_id = CellIDFromNormal(node.position + Vector3.One * node.sideLength / 2.0f, node.cell_id);
        
        if (node.size == 0) return;
        if (node.depth >= debug_tree_depth_limit) return;
        
        const float halfsqrt3 = 0.86602540378f; // Sqrt(3)/2
        if (node.depth == 0 || Mathf.Abs(SampleSDF(node.position + Vector3.One * node.sideLength/2.0f, node.cell_id)) <= node.sideLength * halfsqrt3)
        {
            Vector3[] childPositions = [new Vector3(0,0,0), new Vector3(0,0,1), new Vector3(0,1,0), new Vector3(0,1,1), new Vector3(1,0,0), new Vector3(1,0,1), new Vector3(1,1,0), new Vector3(1,1,1)];
            node.children = new  OctreeNode[8];
            for(int i = 0; i < 8; i++)
            {
                node.children[i] = new OctreeNode(node.position + node.sideLength * childPositions[i] / 2.0f, node.sideLength / 2.0f, node.depth + 1, node.size - 1, node.cell_id);
            }
            foreach(OctreeNode child in node.children) BuildTree(child);
        }
    }
    
    
    public float SampleSDF(Vector3 position, int cell = -1)
    {
        //return planetRadius - position.Length();
        
        if (cell == -1) cell = CellIDFromNormal(position.Normalized());
        return planetRadius + terrainHeight * heights[cell] - position.Length();
    }
    
    
    public int CellIDFromNormal(Vector3 normal, int startCell = 0)
    {
        int id = startCell;
        float bestDot = normal.Dot(positions[startCell]);
		    
        while (true)
        {
            bool improved = false;
		    
            foreach (int nID in neighbours[id])
            {
                float d = normal.Dot(positions[nID]);
				    
                if (d > bestDot)
                {
                    bestDot = d;
                    id = nID;
                    improved = true;
                    break;
                }
            }
			    
            if (!improved)
                return id;
        }
    }
}