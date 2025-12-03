extends Resource
class_name PlanetSimSaveData

const SAVE_PATH : String = "user://planet_sim_save.tres"

@export var height : Array[float] = []
@export var plate_id : Array[int] = []
@export var is_oceanic : Array[bool] = []
@export var stress_rotation_direction : Array[Vector3] = []
@export var debug_neighbour_stress : Array[float] = []
@export var temperature : Array[float] = []
@export var current_type : Array[int] = []
@export var wind_dir : Array[Vector3] = []
@export var precipitation : Array[float] = []
@export var distance_to_ocean_boundary : Array[int] = []
@export var height_gradient : Array[Vector3] = []
@export var climate_zone_id : Array[int] = []


static func write_save(cells : Array[CellData]):
	var save_data = PlanetSimSaveData.new()
	
	var n_cells = cells.size()
	
	save_data.height.resize(n_cells)
	for i in range(cells.size()): save_data.height[i] = cells[i].height
	
	save_data.plate_id.resize(n_cells)
	for i in range(cells.size()): save_data.plate_id[i] = cells[i].plate_id
	
	save_data.is_oceanic.resize(n_cells)
	for i in range(cells.size()): save_data.is_oceanic[i] = cells[i].is_oceanic
	
	save_data.stress_rotation_direction.resize(n_cells)
	for i in range(cells.size()): save_data.stress_rotation_direction[i] = cells[i].stress_rotation_direction
	
	save_data.debug_neighbour_stress.resize(n_cells)
	for i in range(cells.size()): save_data.debug_neighbour_stress[i] = cells[i].debug_neighbour_stress
	
	save_data.temperature.resize(n_cells)
	for i in range(cells.size()): save_data.temperature[i] = cells[i].temperature
	
	save_data.current_type.resize(n_cells)
	for i in range(cells.size()): save_data.current_type[i] = cells[i].current_type
	
	save_data.wind_dir.resize(n_cells)
	for i in range(cells.size()): save_data.wind_dir[i] = cells[i].wind_dir
	
	save_data.precipitation.resize(n_cells)
	for i in range(cells.size()): save_data.precipitation[i] = cells[i].precipitation
	
	save_data.distance_to_ocean_boundary.resize(n_cells)
	for i in range(cells.size()): save_data.distance_to_ocean_boundary[i] = cells[i].distance_to_ocean_boundary
	
	save_data.height_gradient.resize(n_cells)
	for i in range(cells.size()): save_data.height_gradient[i] = cells[i].height_gradient
	
	save_data.climate_zone_id.resize(n_cells)
	for i in range(cells.size()): save_data.climate_zone_id[i] = cells[i].climate_zone_id
	
	
	ResourceSaver.save(save_data, SAVE_PATH)


static func load_save(cells : Array[CellData]) -> Array[CellData]:
	if not ResourceLoader.exists(SAVE_PATH):
		push_warning("Cannot load planet data. No save file found at ", SAVE_PATH)
		return []
	var save_data : PlanetSimSaveData = ResourceLoader.load(SAVE_PATH)
	
	for i in range(cells.size()):
			cells[i].height = save_data.height[i]
			cells[i].plate_id = save_data.plate_id[i]
			cells[i].is_oceanic = save_data.is_oceanic[i]
			cells[i].stress_rotation_direction = save_data.stress_rotation_direction[i]
			cells[i].debug_neighbour_stress = save_data.debug_neighbour_stress[i]
			cells[i].temperature = save_data.temperature[i]
			cells[i].current_type = save_data.current_type[i]
			cells[i].wind_dir = save_data.wind_dir[i]
			cells[i].precipitation = save_data.precipitation[i]
			cells[i].distance_to_ocean_boundary = save_data.distance_to_ocean_boundary[i]
			cells[i].height_gradient = save_data.height_gradient[i]
			cells[i].climate_zone_id = save_data.climate_zone_id[i]
	
	return cells
