using Godot;
using System;

[GlobalClass]
public partial class LandformMountain : Landform
{
    [Export] public Noise cliffRockNoise;
    [Export] public float cliffRockNoiseFrequency;
    
    public override float CalculateDensity(Vector3 position, float height, TerrainGenerator tgen)
    {
        if (noise == null) return 0.0f;

        var flatPos = position.Normalized() * tgen.planetRadius;
        float n = 2f * (1.0f - Mathf.Abs(noise.GetNoise3Dv(flatPos * noiseFrequency))) - 1.0f;
        n *= (noise.GetNoise3Dv((flatPos + Vector3.One * tgen.planetRadius * 0.5f) * noiseFrequency) + 1f / 2.0f);
        //n += (cliffRockNoise.GetNoise3Dv(position * cliffRockNoiseFrequency) * (1.0f - Mathf.Pow(Mathf.Abs(n), 2.0f)));
        return n * noiseStrength;
    }
}
