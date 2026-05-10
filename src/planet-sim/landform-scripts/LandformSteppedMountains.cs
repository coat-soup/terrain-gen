using Godot;
using System;

[GlobalClass]
public partial class LandformSteppedMountains : Landform
{
    
    public override float CalculateDensity(Vector3 position, float height, TerrainGenerator tgen)
    {
        if (noise == null) return 0.0f;
        
        return (noise.GetNoise3Dv(position * noiseFrequency) + 1f / 2f) * noiseStrength * heightDensityCurve.Sample((position.Length() - tgen.planetRadius)/tgen.terrainHeight);
    }
}