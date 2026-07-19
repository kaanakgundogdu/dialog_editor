# Dialog Engine for Godot 4

I am working on a visual novel project, and I needed a simple, node-based dialog system. So, I created **Dialog Engine**, a custom editor plugin for Godot 4.

This plugin helps you write linear or branching narratives using a visual graph editor. Instead of writing complex code, you just connect nodes and click "Compile". The engine turns your graph into a clean, easy-to-read `.txt` file that your game's parser can understand.

![Current Version](/readme_files/gifs/dialog_engine_v001.gif)

## Features

* **Visual Graph Editor:** Create your story by connecting nodes in a clean interface.
* **Smart ID System:** Every new node gets an automatic ID (increases by 1). You can also edit IDs manually if you want to organize your scenes differently.
* **Dialog Blocks:** Add character names, dialogue text, expressions, background images, and music easily.
* **Choice Blocks:** Create branching paths for your players. You can add as many choices as you want.
* **Logic Blocks:** Keep track of player actions. You can modify variables (like `sadness += 10`) or check conditions to jump to different parts of the story.
* **Clean Text Compiler:** It ignores disconnected nodes and only exports your active story into a structured `.txt` file.

## How It Works

1. Open the **Dialog Engine** tab at the top of your Godot editor.
2. Right-click on the grid to add a **Dialog**, **Choice**, or **Logic** block.
3. Fill in the details (speaker, text, etc.) and connect the nodes.
4. Click the **"📝 Compile Scenario (.txt)"** button.
5. The plugin will generate a `compiled_scenario.txt` file in your project folder automatically.
