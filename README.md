Simple Falling Blocks Game

This is a Godot 4 project demonstrating:

    A player at the bottom of the screen moving left and right (in GDScript).
    Falling blocks that spawn from a GDScript function.
    A basic GDExtension (C++ scripts) for demonstration.
    A “Next Block” preview in the top-right corner.

1. Project Overview

    Language: Primarily GDScript (Godot 4.x).
    GDExtension: Contains simple C++ code for movement or speed modification if required by the assignment.
    Objective: Move the player with arrow keys and spawn falling blocks (Space bar). See how many blocks you can avoid or how they interact with an AutoMover for scoring (if present).

2. File/Folder Structure

Key GDScript Files

    player.gd
        Attached to the PlayerNode.
        Handles raw left/right movement.
        Spawns blocks above the player when Space is pressed.
        Maintains a list of block texture paths for random spawning.
        Manages “Next Block” preview sprite.

    blockdrop.gd
        Attached to BlockDrop.tscn (root node typically Area2D or Sprite2D).
        Moves the block downward each frame.
        Can remove itself once off-screen.

    AutoMover.gd (Optional)
        Example of a sprite that moves left/right automatically.
        Increments score if a falling block overlaps it (via area_entered signal).

C++ GDExtension Files 

    keyinput.cpp / keyinput.h: Example of reading arrow keys or spawning objects in C++.
    modifyspeed.cpp / modifyspeed.h: Example of accessing a Godot variable and modifying speed in C++.
    register_types.cpp: Registers the above classes with Godot.

3. Running the Game

    Open the Project in Godot:
        Select the Main.tscn as your startup scene (if not already set in Project Settings → Main Scene).
    Press Play:
        The Main scene appears with the player at the bottom.
        The top-right corner shows the “Next Block” preview if you implemented it.

4. Controls & Gameplay

    Left Arrow / Right Arrow: Move the player left or right.
    Space Bar: Spawn a new falling block above the player.
    Falling Blocks: They drop downward. In some versions, collisions or scoring may occur.

Possible Variations

    If AutoMover is present, a sprite moves automatically across the screen and increments score when a block passes through it.
    If ModifySpeed GDExtension is used, pressing certain keys or triggers might alter the player’s speed.

