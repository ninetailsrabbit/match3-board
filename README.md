<div align="center">
	<img src="icon.svg" alt="Logo" width="160" height="160">

<h3 align="center">Match3 Board</h3>

  <p align="center">
	The core logic and functionality you need to build engaging match-3 games
	<br />
	·
	<a href="https://github.com/ninetailsrabbit/match3-board/issues/new?assignees=ninetailsrabbit&labels=%F0%9F%90%9B+bug&projects=&template=bug_report.md&title=">Report Bug</a>
	·
	<a href="https://github.com/ninetailsrabbit/match3-board/issues/new?assignees=ninetailsrabbit&labels=%E2%AD%90+feature&projects=&template=feature_request.md&title=">Request Features</a>
  </p>
</div>

<br>
<br>

- [📦 Installation](#-installation)
- [Getting started 🚀](#getting-started-)
- [Editor preview 🪲](#editor-preview-)
- [Board size](#board-size)
- [Match configuration](#match-configuration)
- [GridCellUI](#gridcellui)

# 📦 Installation

1. [Download Latest Release](https://github.com/ninetailsrabbit/match3-board/releases/latest)
2. Unpack the `ninetailsrabbit.match3_board` folder into your `/addons` folder within the Godot project
3. Enable this addon within the Godot settings: `Project > Project Settings > Plugins`

To better understand what branch to choose from for which Godot version, please refer to this table:
|Godot Version|match3-board Branch|match3-board Version|
|---|---|--|
|[![GodotEngine](https://img.shields.io/badge/Godot_4.3.x_stable-blue?logo=godotengine&logoColor=white)](https://godotengine.org/)|`main`|`1.x`|

# Getting started 🚀

To start creating your **Match3** game you have available 3 pillars provided from this plugin to build it:

- 🔳 The `Match3Board` node handles the core game mechanics, including grid size, piece setup, and swap movement mode.
- 💎 The `PieceUI` node provides the visual representation and interactive behavior of game pieces. You can customize it or create your own variations.
- 📝 The `PieceDefinitionResource` defines the properties and behaviors of each piece type, such as its match logic and special abilities.

# Editor preview 🪲

This feature provides a preview of your game board before it's fully initialized. This allows you to:

- **_Assess Layout:_** Visualize the size and layout of your board.
- **_Add Empty Spaces:_** Easily adjust the spacing between game pieces.
- **_Experiment with Textures:_** Test different textures for cells and pieces without affecting the final game.

You have available default textures on this plugin to visualize a preview in the editor, feel free to use your own ones.

⚠️ _This preview is temporary and will be removed when the game starts_ ⚠️

---

![editor_preview_match_3](images/editor_preview_match_3.png)

---

- **Preview grid in editor:** Enable or disable the preview
- **Clean current preview:** Removes the current preview from the editor
- **Preview pieces:** The textures to preview in the grid randomly placed on each generation
- **Odd cell texture:** The texture to place in odd cell positions in the board
- **Even cell texture:** The texture to place in even cell positions in the board
- **Empty cells:** Set empty cells where a piece shall not be drawn in the shape of Vector2i(row, column)

# Board size

---

![editor_preview_match_3](images/match3_size_parameters.png)

---

With the `preview enabled`, any changes you make to the board's parameters _(like grid size or piece definitions)_ will be instantly reflected in the preview window. This allows you to quickly iterate and experiment with different configurations

# Match configuration

WIP

# GridCellUI

Each square in the preview represents a GridCellUI node. This node serves as a visual representation of a cell within the game grid and is not designed for customization.
