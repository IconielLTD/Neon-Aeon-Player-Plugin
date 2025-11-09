# Neon Aeon Player

A narrative game creation plugin for Godot 4, designed for creators using GenAI tools or traditional methods to build branching narrative games.

## Overview

Neon Aeon Player is part of the Neon Aeon workflow, working alongside the [Neon Aeon Asset Management System](https://github.com/IconielLTD/Neon-Aeon---Asset-Management-System) to enable easy creation of branching narrative stories using Ogv video, Ogg audio, and PNG image assets.

## Features

- JSON-driven branching narrative system
- Support for multimedia content (video, audio, images)
- Optimized for GenAI-generated content workflows
- Simple setup and integration
- Audio bus support for background music and dialogue

## Requirements

- Godot 4.x (built on v4.3.1)
- [Neon Aeon Asset Management System](https://github.com/IconielLTD/Neon-Aeon---Asset-Management-System)

## Installation

1. Copy the `addons` folder from this repository into your Godot project
2. Go to **Project > Project Settings > Plugins**
3. Enable **Neon Aeon Player** by checking the box next to it

## Quick Start

1. **Prepare your assets**: Place your Ogv videos, Ogg audio, and PNG images in organized folders within your project's `res://` directory

2. **Create your story**: Use the Neon Aeon Asset Management System to build your branching narrative, then export to JSON

3. **Set up your scene**:
   - Create a new 2D scene
   - Add a `NeonAeonPlayer` node as a child

4. **Configure audio buses**:
   - Go to the Audio section in Project Settings
   - Create two audio buses: `BGM` (background music) and `Dialogue`

5. **Load your story**:
   - Select the `NeonAeonPlayer` node
   - In the Inspector, find the **Project File** field
   - Enter the path to your JSON file (e.g., `res://your_story.json`)

6. **Play**: Press play and enjoy your adventure!

## Demo Project

This repository includes **Happy Hills**, a simple children's story demo. Meet the Hippos in the Happy Hills and choose different ways to have a nice time. The demo shows basic functionality and serves as a reference for setting up your own projects.

## Roadmap

1. Test on larger, more complex stories
2. Integrate the Asset Management System directly into the Godot plugin
3. Game controller support
4. Enhanced customization options (fonts, style boxes, choice icons)

## Contributing

I'm a solo developer working on this project in my free time without backing, so response times may vary. If you have a substantial update or feature to propose, please fork the repository and contact me to discuss it before submitting a pull request.

## License

**Software** included in this repo is subject to the **MIT License** - see LICENSE file for details

**Video, audio, and image assets** intended for demonstration use are subject to the **Artlist Pro Licence** and should not be used for your own projects. See LICENSE file for details

## Get Creating!

Most importantly, have fun creating your own narrative adventures. Let me know what you create - I can't wait to play them!

---

*Part of the Neon Aeon workflow. For asset management, see the [Neon Aeon Asset Management System](https://github.com/IconielLTD/Neon-Aeon---Asset-Management-System).*