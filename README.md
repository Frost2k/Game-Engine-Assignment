# Necromancer Keep

A first-person dungeon exploration game developed in Godot Engine with custom C++ GDExtension modules.

## 1. Overview

Necromancer Keep is a first-person adventure/dungeon crawler where players navigate through mysterious environments, collect magical gems, and battle against necromantic forces. The game features a robust UI system, inventory management, and custom minimap functionality implemented through C++ GDExtension.

### 1.1 Demo

Youtube Video demo [link](https://youtu.be/lmcNlymCDZ8)

## 2. Features Implemented

### 2.1 User Interface System (GDExtension)
- Modular UI framework built with custom C++ components
- Dynamic health and status bars with animated transitions
- Gem inventory display system with real-time updates
- Start menu and death screen with seamless scene transitions

### 2.2 Minimap System (GDExtension)
- Real-time player position tracking using C++ for optimized performance
- Dynamic enemy and point-of-interest indicators
- Automatic discovery and reveal mechanics
- Customizable display options and zoom functionality

### 2.3 Player Mechanics
- Fluid first-person movement with WASD controls
- Sprint, jump, and crouch capabilities
- Health and damage system with visual feedback
- Projectile combat with visual effects

### 2.4 Collection/Inventory System
- Five distinct gem types with unique effects
  - Purple (Magic): Energy restoration
  - Red (Health): Health restoration
  - Blue (Shield): Temporary shield bonus
  - Green (Speed): Movement speed boost
  - Yellow (Luck): Increased drop rates
- Inventory management with visual representation
- Use/consume functionality for gems
- Drop mechanics for sharing or discarding items

### 2.5 Enemy AI (Godot/GDExtension)

- 6 enemy states: Idle, Wander, Chase, Attack (Spell), Attack (Melee), and Flee
- 2 enemy traits: Brave and Flees
- Pathfinding and navigation
- obstacle avoidance

## 3. Controls

- **Movement**: WASD keys
- **Look**: Mouse
- **Jump**: Space bar
- **Sprint**: Shift
- **Shoot**: Left Mouse Button
- **Fly**: ~
- **Pickup Items**: O keys (can pick up keyrings, candles, chair and coins)

## 4. Implementation Details

### 4.1 UI System (GDExtension)
The UI system was implemented using C++ via GDExtension to create a highly optimized and responsive interface. Key components include:

- **HealthDisplay**: A custom C++ component that handles health visualization with smooth animations and visual effects when damage is taken.
- **GemsUI**: Manages the gem collection interface with real-time updates and visual feedback.
- **MenuSystem**: Handles the main menu, death screen, and transition effects with minimal performance impact.

The UI system was designed to be extensible, allowing for easy addition of new elements and customization.

### 4.2 Minimap Implementation (GDExtension)
The minimap was built using custom C++ components to ensure optimal performance even with numerous tracked entities. Features include:

- **SpatialMapping**: Converts 3D world coordinates to 2D minimap space efficiently.
- **EntityTracker**: Maintains and updates positions of players, enemies, and points of interest.
- **CustomRenderer**: Provides a high-performance rendering pipeline for the minimap.

### 4.3 AI Subsystem (Godot/GDExtension)

The AI subsystem was built using a combination of Godot and GDExtension. GDExtension handled Finite State Machine logic, while Godot was used for its built-in A* pathfinding and routing.

- Implemented with Finite State Machine.
- FSM logic is handled in C++ with a GDExtension: `AIOrchestrator`. 
- Adaptive behavior (C++): repeated ranged attacks makes the AI more likely to charge at the player
- Navigation and pathfinding using Godot's built-in navigation system (A-star)
- 6 enemy states: Idle, Wander, Chase, Attack (Spell), Attack (Melee), and Flee
- 2 enemy traits: Brave and Flees

## 5. Team Contributions

### 5.1 UI and Collection Systems (Implemented) Thomas
- Custom UI framework with health, inventory, and status displays
- Gem collection system with different gem types and effects
- Start menu and death screen implementation
- Visual feedback systems for player actions

### 5.2 AI Pathfinding and Enemy Behavior (Implemented) Galen
Key goals:
- Custom pathfinding algorithms for dynamic environments
- Context-aware enemy behavior
- Finite State Machine for enemy AI with multiple states

### 5.3 Networking and Multiplayer (TBD)
*[This section will be completed by team member implementing the networking features]*

Key goals:
- Lobby and matchmaking system
- State synchronization with prediction algorithms
- Client-side prediction and server reconciliation
- Drop-in/drop-out multiplayer support

## 6. Building and Running the Project

### 6.1 Prerequisites
- Godot 4.1 or higher
- C++ build tools (Visual Studio 2019+ or equivalent on other platforms)
- SCons build system

### 6.2 Building the GDExtension Modules

#### 6.2.1 Setup

```bash
# Install scons
python -m venv game-venv
game-venv\Scripts\activate.bat
pip install scons

# Install godot-cpp
git init
git submodule add -b 4.x https://github.com/godotengine/godot-cpp
cd godot-cpp
git submodule update --init
```

#### 6.2.2 Build Steps

1. Navigate to the gdextension directory (`src`)
2. Run `scons platform=<platform>` where `<platform>` is your target platform (windows, linux, macos)
3. The compiled libraries will be placed in the appropriate location automatically

### 6.3 Running the Game
1. Open the project in Godot Engine
2. Run the project or export for your target platform

## 7. Future Work

- Additional gem types and effects
- More diverse environments and enemy types
- Expanded combat mechanics
- Persistent player progression system
- Level editor for custom dungeon creation

## 8. License

This project is developed as part of CS-5891 Game Engine course and is intended for educational purposes.

## 9. Credits

Developed by [Your Team Name]
- UI and Collection Systems: Thomas Scott
- AI Pathfinding: Galen Wei
- Networking: [Team Member Name]
- Additional contributions: [Other Team Members] 
