# Cel-Shaded 3D Game

This project demonstrates a 3D Godot 4 game that features:

Cel (toon) shading (fragment shader).

A mesh outline effect (vertex shader).

A simple water shader (from a Godot tutorial example).

A compute shader (illustrating advanced shader concepts).

A custom GDExtension in C++ to control specific shader parameters dynamically from native code.
<img src=https://github.com/user-attachments/assets/069a7272-e7a7-43e7-81d4-5496721d9e76 width=50% height=50%>


https://youtu.be/Tc5avZ11JJA

# 1. Project Overview / Purpose

Language: Primarily Godot 4 GDScript for gameplay logic, plus:

ShaderLanguage (GSL) for custom materials (cel-shading and outline).

C++ (GDExtension) for extended control of shader parameters.

Goal: Demonstrate how to write both vertex and fragment shaders to achieve a cartoon-like or stylized rendering effect, then manage them in real time using GDScript and (optionally) C++.

Key Features:

Cel (Toon) Shading: Quantizes lighting into discrete bands, giving objects a “cartoon” look.

Mesh Outline: Uses a vertex shader to slightly expand and flip culling, creating a bold, cartoonish edge around 3D models.

Simple Water Shader: Based on the official Godot “Your second 3D shader” tutorial – placed beneath the level for an animated water surface.

Compute Shader: Contains a minimal GLSL compute_example.glsl demonstrating how to use compute shaders in Godot 4.

GDExtension: A custom C++ class OutlineController3D, which inherits from Node3D and updates the outline shader’s uniforms (color, thickness, noise scale, etc.) in real time.

# 2. File/Folder Structure

<img src=https://github.com/user-attachments/assets/88dc54d5-415e-4cf1-94b9-9e75892a5cd8 width=50% height=50%>





Key Shader Files

CelToon.gdshader

Implements a fragment function that quantizes lighting into discrete bands for a cartoon effect.

Uniforms: base_color, toon_opacity, toon_levels, etc.

Outline.gdshader

Implements a vertex function that inflates the mesh slightly and uses render_mode cull_front for an outline effect.

Uniforms: outline_color, outline_thickness, deformation_strength, etc.

simple_water.gdshader

From the “Your second 3D shader” tutorial. Uses PBR-like parameters (ALBEDO, ROUGHNESS, METALLIC) and wave math in the vertex shader.

compute_example.glsl

A minimal example of a compute shader, showing how to multiply an array of floats by 2 on the GPU.

GDExtension Files

outline_controller_3d.h / outline_controller_3d.cpp

A custom C++ node (OutlineController3D) that syncs certain outline shader uniforms (outline_color, noise_scale, deformation_strength, etc.) from native code at runtime.

Demonstrates how to create a GDExtension class that updates a ShaderMaterial’s parameters each frame.

# 3. Running the Game

Open the Project in Godot 4.

Go to Project → Project Settings → Main Scene or open scenes/main.tscn manually and press the Play button.

Player Controls:

W, A, S, D to move.

Mouse to look around (in 3D).

Shift key to move faster (run).

~ (tilde) key to enable fly mode.

Shader Scenes:

The main scene has two “Godot Bot” figures with the CelToon shader.

An Outline effect can be added to these or other meshes.

A water plane with the simple water shader is placed “under the level,” visible if you look through the window or below the map.

GDExtension Usage:

If you attach the OutlineController3D node to any 3D model and assign its ShaderMaterial, you can dynamically tweak the outline properties in real time.

# 4. Controls & Gameplay

Movement: Use W, A, S, D (and mouse look).

Run: Hold Shift to increase movement speed.

Fly: Press ~ to toggle flight mode (no gravity).

Observe Cel Shading: The “Godot Bot” characters have discrete shading bands visible on their surfaces.

Observe Outline: Outline can be toggled by applying the OutlineMaterial to any mesh, or hooking up OutlineController3D.

Water: Look out the window or below the level to see the wave animation.

Compute Shader: Not directly visible in the scene, but compute_example.glsl can be run from GDScript to process data on the GPU.

# 5. Differences: GDScript vs. GDExtension

GDScript

Standard node logic, such as moving the player, handling input, or simple animation.

Can directly set shader uniforms with material.set_shader_parameter("param", value).

GDExtension (C++)

Demonstrates custom classes for specialized effects or performance-critical code.

Example: OutlineController3D updates outline_color, noise_scale, etc. every frame from C++.

This approach can be more performant and is useful if you want to integrate complex logic or external libraries at the native level.

# 6. Summaries of the Godot Shader Tutorials

This project also includes tutorial examples from the official Godot documentation on shaders. Below are brief highlights of each:

## Tutorial 1: Your First 3D Shader

Goal: Learn how vertex displacement works in a spatial shader.

Key Steps:

Created a plane, subdivided it into many vertices.

<img width="378" alt="plane_mesh" src="https://github.com/user-attachments/assets/08b88426-e934-4bd7-a79c-f36038b414db" />
<img width="579" alt="subdivde" src="https://github.com/user-attachments/assets/dd06083a-997a-492f-b4f5-1af7581f7316" />

Added a NoiseTexture uniform (sampler2D) to displace vertices (heightmap).

Used VERTEX adjustments in the vertex() function to produce little hills.

<img width="774" alt="vertex" src="https://github.com/user-attachments/assets/e73b5477-2810-4f47-8bff-af4160f022e2" />

Combined a normal map to fix lighting issues or recalculate normals.

<img width="474" alt="light" src="https://github.com/user-attachments/assets/6598ed3c-f3f8-4746-a9ef-0672a97ffbdc" />

Result: A wavy or bumpy plane that reacts properly to light.

<img width="667" alt="final" src="https://github.com/user-attachments/assets/44242423-02e8-4ff3-a73d-a15c9e70f0eb" />

## Tutorial 2: Your Second 3D Shader

Goal: Turn the previous terrain into water via fragment shading.

Key Steps:

Learned about PBR properties (METALLIC, ROUGHNESS, etc.) and how to set them in the fragment() function.

<img width="689" alt="advanced water" src="https://github.com/user-attachments/assets/c7a19723-7d2c-4531-810b-934bd9e9201d" />

Used render_mode specular_toon for stylized highlights.

<img width="733" alt="fresnel" src="https://github.com/user-attachments/assets/d9f00257-9c5f-4dc8-a99b-dcc9aaa2b56e" />

Computed a fresnel term to simulate reflectance at shallow angles.

Animated wave motion by combining multiple sine/cosine layers.

<img width="383" alt="added to game" src="https://github.com/user-attachments/assets/a8b40bdd-af3f-42d2-9c12-b0080c9d2504" />

Result: A dynamic water surface with simple wave motion.

## Tutorial 3: Using Compute Shaders

Goal: Execute general-purpose GPU code for tasks not strictly tied to rendering.

Key Steps:

Wrote a GLSL file (compute_example.glsl) with a #[compute] directive.

Used a local RenderingDevice to create buffers, dispatch workgroups, and synchronize results.

Demonstrated reading back from GPU memory to see changes (multiplying an array of floats).

Result: A stepping stone to offloading complex calculations to the GPU, beyond just vertex/fragment shading.

<img width="630" alt="rendering engine" src="https://github.com/user-attachments/assets/c4dad2f2-9773-4fc6-815b-b7f57a5f5b1e" />


# 7. Custom C++ Module

Custom C++ Module: This project uses an OutlineController3D GDExtension class to allow for manually setting ShaderMaterial parameters only from GDScript.

# 8. Extra Credit

Interactive Shaders: Player-driven changes (lighting) demonstrate real-time updates, such as adjusting the outline thickness.

