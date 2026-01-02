using Godot;
using System;

[GlobalClass]
public partial class ClimateZoneFoliageData : Resource
{
    [Export] public int climateZoneID;
    [Export] public Mesh[] meshes;
    [Export] public float[] weights;

    private float totalWeight = -1;
    private Random rnd = new Random();
    
    public void Setup()
    {
        totalWeight = 0;
        if(meshes.Length != weights.Length) GD.PushError("Climae zone foliage data " + climateZoneID + " invalid. Meshes and weights do not match.");
        for (int i = 0; i < weights.Length; i++) totalWeight += weights[i];
    }

    
    public Mesh SelectMesh()
    {
        if(totalWeight == -1) Setup();
        
        float w = (float)rnd.NextDouble() * totalWeight;

        for (int i = 0; i < weights.Length; i++)
        {
            w -= weights[i];
            if (w <= 0) return meshes[i];
        }
        
        GD.PushError("Climate zone foliage couldn't select mesh.");
        return null;
    }
}
