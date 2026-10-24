using Godot;
using System;

[GlobalClass]
public partial class LandformSteppedMountainsDeprecated : LandformDeprecated
{
    
    public override float CalculateDensity(Vector3 position, float height, TerrainGeneratorDeprecated tgen)
    {
        if (noise == null) return 0.0f;
        
        return (noise.GetNoise3Dv(position * noiseFrequency) + 1f / 2f) * noiseStrength * heightDensityCurve.Sample((position.Length() - tgen.planetRadius)/tgen.terrainHeight);
    }
}