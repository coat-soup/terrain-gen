using Godot;
using System;

[GlobalClass]
public partial class Util : Node
{
    public static Vector2 PositionToLatLong(Vector3 position)
    {
        position = position.Normalized();

        float latitude = Mathf.RadToDeg(Mathf.Asin(position.Y));

        float longitude = Mathf.RadToDeg(Mathf.Atan2(position.Z, position.X));

        return new Vector2(latitude, longitude);
    }
    
    
    public static Vector3 LatLongToPosition(float latitude, float longitude, float height)
    {
        float latRad = Mathf.DegToRad(latitude);
        float lonRad = Mathf.DegToRad(longitude);

        float x = height * Mathf.Cos(latRad) * Mathf.Cos(lonRad);
        float y = height * Mathf.Sin(latRad);
        float z = height * Mathf.Cos(latRad) * Mathf.Sin(lonRad);

        return new Vector3(x, y, z);
    }
}
