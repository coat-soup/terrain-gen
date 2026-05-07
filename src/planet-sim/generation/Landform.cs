using Godot;
using System;

[GlobalClass]
public partial class Landform : Resource
{
    [Export] public String name;
    [Export] public Vector2 upliftRange = new Vector2(0,100);
    [Export] public Vector2 precipitationRange = new Vector2(0,100);
    [Export] public Vector2 temperatureRange = new Vector2(-500,500);
    [Export] public Vector2 windRange = new Vector2(0,100);
    [Export] public Vector2 magmaRange = new Vector2(0,100);

    [Export] public int riverDistance = -1;
    
    [Export] public Noise noise;
    [Export] public float noiseStrength = 1.0f;
    [Export] public float noiseFrequency = 0.1f;
    
    public virtual float CalculateDensity(Vector3 position, float height, TerrainGenerator tgen)
    {
        var flatPos = position.Normalized() * tgen.planetRadius;
        if (noise == null) return 0.0f;
        return (noise.GetNoise3Dv(flatPos * noiseFrequency) + 1f / 2.0f) * noiseStrength;
    }
}
