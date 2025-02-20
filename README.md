Godot 4 Physics Debugging & Magnetic Simulation (GDExtension)

This project provides tools for visualizing physics interactions and simulating magnetic-like attraction in Godot 4 using GDExtension (C++). It includes real-time debugging features for physics bodies and customizable parameters for orbit-based motion.
Project Overview

    Language: Primarily Godot 4 C++ GDExtension, with standard Godot node interactions.
    Objective:
        Provide a debugging tool to visualize collision shapes and forces.
        Implement a MagneticOrbit system, allowing one object to orbit another with adjustable parameters.
    Key Features:
        MagneticOrbit (C++): Simulates a gravitational/magnetic-like pull between objects, with adjustable settings for force, distance, and rotation.
        DebugVisualizer (C++): Provides real-time collision shape visualization and force vector rendering.

File/Folder Structure

ProjectRoot/
├─ gdextension/
│   ├─ magnetic_orbit.cpp / .h  # Magnetic simulation system
│   ├─ debug_visualizer.cpp / .h  # Debugging visuals
│   ├─ register_types.cpp
│   └─ ...
├─ scenes/
│   ├─ world.tscn  # Example setup for MagneticOrbit
│   └─ ...
└─ README.md (this file)

Key Components
1. MagneticOrbit (C++)

The MagneticOrbit node creates a magnetic/gravitational-like effect between two objects in a 2D space. One object (e.g., a player) attracts another (orbit object) within a configurable range.
Adjustable Settings:

Users can fine-tune the simulation using the following properties:
Property	Default Value	Description
max_distance	300.0f	The maximum distance at which the orbit object is affected. If the player moves beyond this, forces are ignored.
orbit_distance	80.0f	The ideal distance at which the object should orbit instead of just being pulled straight in.
magnetic_force	10000.0f	The strength of attraction between the two objects. Higher values result in stronger pull.
swirl_factor	0.5f	Introduces a rotational force, causing the orbiting object to spiral around the player instead of moving in a straight line.

📌 Example Use Case:
Attach MagneticOrbit to an object in your scene and set player_path to your player node. Adjust the parameters to control how objects move in response to magnetic forces.
2. DebugVisualizer (C++)

The DebugVisualizer is a real-time physics debugger that helps visualize forces and collision shapes.
Features:

    Show collision shapes: Draws CollisionShape2D and CollisionPolygon2D outlines.
    Show force vectors: Displays force directions applied by MagneticOrbit.
    Works with RigidBody2D, CharacterBody2D, and StaticBody2D.

Adjustable Settings:
Property	Description
show_collision_shapes	Toggle whether to visualize collision shapes for physics objects.
show_forces	If enabled, draws force vectors applied to the orbit object in MagneticOrbit.

📌 Example Use Case:
Enable DebugVisualizer, set magnetic_orbit_path to an active MagneticOrbit, and watch as forces are drawn in real time.
Running the Project

    Open the project in Godot 4.
    Load either:
        MagneticOrbitExample.tscn to test magnetic attraction mechanics.
        DebugVisualizerExample.tscn to see physics forces and collision shapes.
    Press Play and experiment with adjusting parameters via the Inspector.

Controls & Gameplay

    Move the player to attract the orbit object.
    Adjust magnetic_force and swirl_factor for different effects.
    Use DebugVisualizer to see force vectors in action.