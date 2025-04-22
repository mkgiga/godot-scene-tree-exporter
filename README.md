# Godot Scene Tree ASCII Exporter

A simple plugin for Godot 4.x that turns your active scene tree into an ASCII tree.

```
root: Node/
└─ Game: Node (Game.gd)
  ├─ PacketHandler: Node (PacketHandler.gd)
  ├─ WorldEnvironment: WorldEnvironment
  │ ├─ DirectionalLight3D: DirectionalLight3D
  │ └─ World: Node3D % (MapManager.gd)
  ├─ "Free fly camera": CharacterBody3D (free_fly_startup.gd)
  └─ GUI: CanvasLayer %
	└─ Editors: Control %
	  └─ MapEditor: Control % (MapEditor.gd)
		├─ TerrainControls: VBoxContainer %
		│ └─ HBoxContainer: HBoxContainer
		└─ BrushSettings: HBoxContainer
		  └─ BrushSize: HBoxContainer % (HInputContainer.gd)
			├─ LblBrushSize: Label
			├─ SlBrushSize: HSlider
			└─ Value: Label
```

# Install
1. Clone this repository into your project's `res://addons` directory or download it from the AssetLib.
2. Now open `Project > Project Settings > Plugins` and click the checkbox on Scene Tree Exporter.

# Usage
Click the <img src="./icon.svg"/> icon in the very top right corner of the Godot window to copy the current scene to your clipboard.
