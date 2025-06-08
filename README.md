# Ocean Trading Game

A procedurally generated ocean exploration and trading game built with LÖVE2D (Lua).

## Features

### 🚢 Realistic Boat Physics
- Momentum-based movement with throttle and steering
- Ocean currents and wave effects
- Collision detection with land masses
- Dynamic wake trail effects

### 🌊 Procedural World Generation
- Infinite ocean world with islands and continents
- Minecraft-style chunk loading system
- Configurable render distance for performance
- Multiple biomes (ocean, shallow water, beaches, grasslands, forests, mountains)

### 💰 Dynamic Economy
- Supply and demand-driven market prices
- Trading between coastal cities
- Multiple resource types (food, materials, luxury goods)
- Reputation system affecting trade prices

### 🗺️ Advanced Map System
- Full-screen world map with zoom and pan
- Fog of war exploration system
- Toggle to show all terrain (for testing)
- Mini-map overlay for quick reference

### ⚡ Performance Optimized
- Efficient chunk loading/unloading
- Zero-garbage wake trail system
- Optimized rendering with culling
- Smooth 60+ FPS gameplay

## Controls

### Boat Movement
- **W** - Forward throttle
- **S** - Reverse throttle
- **A** - Steer left
- **D** - Steer right
- **Space** - Emergency brake/anchor

### Navigation
- **M** - Toggle full-screen map
- **Tab** - Toggle mini-map overlay
- **F** - Toggle fog of war (when in map mode)

### Map Controls
- **Mouse Wheel** - Zoom in/out
- **Click & Drag** - Pan around map
- **ESC** - Close map

## Installation & Running

### Requirements
- [LÖVE2D](https://love2d.org/) (version 11.4 or higher)

### Running the Game
1. Download or clone this repository
2. Make sure you have the boat image `boat1.png` in the root directory
3. Run with LÖVE2D:
   ```bash
   love .
   ```
   Or drag the folder onto the LÖVE2D executable

## File Structure

```
exploreboat/
├── main.lua              # Game entry point
├── conf.lua              # LÖVE2D configuration
├── boat1.png             # Boat sprite image
├── systems/
│   ├── world/            # World generation & chunks
│   ├── boat/             # Boat physics & controls
│   ├── economy/          # Trading & markets
│   ├── ui/               # User interface
│   └── render/           # Graphics & effects
├── entities/             # Game entities
├── utils/                # Utility functions
└── assets/               # Game assets
```

## Technical Details

### World Generation
- Uses multi-octave simplex noise for realistic terrain
- Guaranteed water spawn area (1500 unit radius)
- Dynamic city placement on coastlines
- Resource distribution based on biomes

### Chunk System
- 512x512 pixel chunks
- Configurable render distance (default: 4 chunks)
- Automatic unloading of distant chunks
- Asynchronous generation to prevent stuttering

### Performance Features
- Circular buffer wake trail (zero garbage collection)
- Spatial culling for rendering
- Level-of-detail for distant objects
- Optimized market update scheduling

## Development

Built using LÖVE2D framework with modular architecture for easy expansion and modification.

### Key Systems
- **WorldGen**: Procedural terrain and chunk management
- **BoatPhysics**: Realistic boat movement simulation
- **Economy**: Supply/demand market simulation
- **Renderer**: Optimized graphics with effects
- **UI**: HUD, maps, and user interface

## License

[Add your preferred license here]

## Contributing

[Add contribution guidelines if desired]