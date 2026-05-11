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
    [Export] public Vector2 noiseBounds = new Vector2(0.5f, 1.0f);
    [Export] public float noiseFrequency = 0.1f;
    
    [Export] public Curve heightDensityCurve;
    
    public virtual float CalculateDensity(Vector3 position, float heightPercent, TerrainGenerator tgen)
    {
        var flatPos = position.Normalized() * tgen.planetRadius;
        if (noise == null) return 0.0f;
        
        float n = (noise.GetNoise3Dv(position * noiseFrequency) + 1f / 2.0f) * noiseStrength;
        return n;
        n = heightDensityCurve.Sample(heightPercent);

        //float targetHeight = 0.5f + ((noise.GetNoise3Dv(flatPos * noiseFrequency) + 1f) / 2f) * noiseStrength / 2.0f;
        float targetHeight = Mathf.Remap(noise.GetNoise3Dv(flatPos * noiseFrequency), -1f, 1f, noiseBounds.X, noiseBounds.Y);
        //float targetHeight = noise.GetNoise3Dv(flatPos * noiseFrequency) * noiseStrength; // IF USING DENSITY CURVE

        float density = (heightPercent - targetHeight);// - heightDensityCurve.Sample(heightPercent);
        //density = SampleDensityCurve(heightPercent) * noise.GetNoise3Dv(flatPos * noiseFrequency);
        return density;
    }

    public float SampleDensityCurve(float heightPercent)
    {
        if (heightPercent > 1f) return 0f;
        if (heightPercent < 0f) return 1f;
        return heightDensityCurve.Sample(Mathf.Clamp(heightPercent, 0f, 1f));
    }
}
