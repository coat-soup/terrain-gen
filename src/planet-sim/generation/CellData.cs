using Godot;
using Godot.Collections;

[GlobalClass]
public partial class CellDataCS : RefCounted
{
	[Export] public int id;
	public Array<int> neighbours = new Array<int>();
	[Export] public Vector3 unit_pos;
	[Export] public float height = 0.0f;
	[Export] public int plate_id = -1;
	[Export] public bool is_oceanic = false;
	[Export] public Vector3 stress_rotation_direction;
	[Export] public float debug_neighbour_stress = 0.0f;
	[Export] public float temperature = 0f;
	[Export] public int current_type = -100;
	[Export] public Vector3 wind_dir = Vector3.Zero;
	[Export] public float precipitation = 0f;
	[Export] public int distance_to_ocean_boundary = -1;
	[Export] public Vector3 height_gradient;
	[Export] public int climate_zone_id = -1;
	
	public CellDataCS() { } // required by godot to recognise the class
}
