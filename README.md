RPG-Style Game with Godot 4 and GDExtension

This project demonstrates a simple 2D RPG-style game using both GDScript and C++ GDExtension to illustrate enhanced input handling, floating items, and standard GDScript enemy AI.
1. Project Overview

    Language: Primarily Godot 4 GDScript, with key mechanics implemented in C++ (GDExtension).
    Objective: Create a small RPG-style scene in which the player can move around, attack with GDScript logic, and see certain items or behaviors driven by a C++ module.
    Key Features:
        Enhanced Input Handling (C++): Press WASD for movement, hold Space to increase movement speed, and let F handle attacks (via GDScript).
        Floating Items (C++): Items that float when the player is nearby, using a custom “floating_item” GDExtension node.
        Enemies (GDScript): Simple AI that follows the player when too close, showcasing GDScript node logic.

2. File/Folder Structure

ProjectRoot/
├─ gdscripts/
│  ├─ player.gd
│  ├─ enemy.gd
│  └─ ...
├─ gdextension/
│  ├─ enhanced_input_handling.cpp / .h
│  ├─ floating_item.cpp / .h
│  ├─ register_types.cpp
│  └─ ...
├─ scenes/
│  ├─ Main.tscn
│  ├─ Player.tscn
│  ├─ Enemy.tscn
│  ├─ FloatingItem.tscn
│  └─ ...
└─ README.md (this file)

Key GDScript Files

    player.gd
        Attached to Player.tscn.
        Handles standard movement (WASD) and attack logic on the F key.
        Coordinates any GDScript-based interactions, such as simple collisions with enemies.

    enemy.gd
        Simple AI that follows the player if they get too close.
        Demonstrates GDScript-based logic for node chasing.

GDExtension (C++) Files

    enhanced_input_handling.cpp/h
        A Node2D (or similar) that overrides _process() or _input() to implement enhanced input:
            WASD for movement (an alternative approach to GDScript).
            Space Bar for a speed boost (sprint).
            Demonstrates the difference between using GDExtension for input logic vs. using GDScript.

    floating_item.cpp/h
        A custom node that floats up/down if the player is within a certain distance.
        Illustrates how to read the player’s position in C++ and update item states.
        Contrasts with enemies, which are purely in GDScript.

    register_types.cpp
        Registers the above classes (EnhancedInputHandling, FloatingItem) so Godot sees them as scriptable node types.

3. Running the Game

    Open the project in Godot 4.
    Check Project Settings → Main Scene or open Main.tscn manually and press Play.
    Optional: If you want to attach the GDExtension nodes, ensure you have:
        A child node on Player named EnhancedInput (script: enhanced_input_handling).
        Some item scenes with floating_item as their root node.

4. Controls & Gameplay

    Movement:
        GDScript approach: The default movement is in player.gd—press WASD to move.
        OR if you are testing the C++ approach, attach EnhancedInputHandling to the Player for _input() capturing arrow keys or WASD.
    Sprint: Hold Space (in the C++ example) to increase the speed.
    Attack: Press F (handled by GDScript in player.gd).

Enemies:

    They follow the player (enemy.gd) if the player is within detection range.
    Showcases GDScript-based AI logic, contrasting with the item’s C++ logic.

Floating Items:

    Placed in the level as FloatingItem.tscn (with floating_item GDExtension).
    When the player is close, items float up and down. If the player is far, they remain idle.
    Demonstrates distance checking in C++ vs. the enemy’s GDScript-based approach.

5. Differences: C++ vs. GDScript

    Enhanced Input (C++):
        Key combos (Space + movement) for sprint.
        Attack is left in GDScript to show how each can handle input differently.

    Floating Items (C++) vs. Enemies (GDScript):
        Items only float near the player using a GDExtension node that checks distance in _process().
        Enemies track the player via pure GDScript, illustrating two ways to do “nearby” node logic.

6. Basic Instructions

    Move around with WASD (or arrow keys if you mapped them).
    Hold Space to move faster (if the EnhancedInput node is active).
    Press F to attack.
    Get near any floating items to see them bob up/down.
    Beware enemies—if you’re close, they chase you. Attack them or run!