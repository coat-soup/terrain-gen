# Real-Time Terrain Generation With Real World Models

<p align="center">
  <img src="gallery/planet_demo_01.png?raw=true">
</p>

This is a project exploring algorithmic terrain generation based on real-world environmental models. It works in two stages: 1. simulate a low-resolution global planet with all necessary data for terrain shaping and biome generation, 2. use classical methods to generate terrain in real-time for a human-sized character/camera, combining random noise-based proceduralism and the accurate pregenerated data from step 1.


## Built With
- ![Godot Engine](https://img.shields.io/badge/GODOT-%23FFFFFF.svg?style=for-the-badge&logo=godot-engine)



# Installation & Setup
This project runs entirely within the Godot editor, built with version 4.4.1, which can be downloaded here: https://godotengine.org/download/archive/4.4.1-stable/

Once opening the project with Godot, navigate to the scene `planet-sim/generation/mesh_generation.tscn` and open it in the editor.



# Using The World Simulation
All code is run in editor via editor tooling; you do not need to press play.

In the mesh generation scene, the three nodes that control the simulation are `MeshGenerator`, `SimulationPipeline` and `CellDataVisualiser`. You can select them in the scene tree and then change their properties and run them in the inspector tab.


## Simulating a planet:
1. Select the `MeshGenerator` node, and press the `Generate` button in the inspector. Planetary resolution can be controlled by the parameter `N Subdivisions`; recommended range is 4-6. Going beyond 7 subdivisions is not recommended unless you are running on a very powerful device, and may otherwise cause the editor to freeze.
<p align="center">
  <img src="gallery/mesh_gen_inspector.PNG?raw=true">
</p>

2. Select the `SimulationPipeline` node, and press `Simulate`. Simulation parameters can be tweaked by selecting the individual pipeline steps and changing parameters. You can resimulate the planet freely without generating a new mesh as in step 1
<p align="center">
  <img src="gallery/simulation_pipeline_inspector.PNG?raw=true">
</p>

3. Select the `CellDataVisualiser` node, and display different pipeline/data layers by changing the `Vis Type` parameter. The `ColourMesh` button will regenerate the visualisation if needed.
<p align="center">
  <img src="gallery/cell_data_vis_inspector.PNG?raw=true">
</p>

4. Enjoy your simulated planet :)
<p align="center">
  <img src="gallery/planet_demo_02.PNG?raw=true">
</p>


You can orbit the camera around the planet by holding down the middle mouse button in the 3D View window (where the planet is) and dragging it around.