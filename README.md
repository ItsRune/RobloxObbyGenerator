# Roblox Obby Generator

## Table of Contents

- [About](#about)
- [Getting Started](#getting_started)

<!-- - [Usage](#usage) -->
<!-- - [Contributing](../CONTRIBUTING.md) -->

## About <a name = "about"></a>

`Roblox Obby Generator` is self-explanatory, it uses Luau to generate a playable Obby (Obstacle course) for the Roblox game platform. The motivation for this project was to learn how to use Lune's built-in roblox module to directly act on the XML/Binary of Roblox Studio.

<!-- TODO: Add more sentences. -->

## Getting Started <a name = "getting_started"></a>

1. Download & install [Lune](https://lune-org.github.io/docs).
2. Run `git clone <TO_INSERT>`
3. Open terminal/command prompt and navigate to the path of the cloned repository.
4. Run `lune run cli.luau`

You'll be prompted:

```
Please select the generation type you'd like to use:
 - Generate
 - Generate & Publish
```

## Additionall

If you import a module and the type checker is on your butt, you can use the module `tools/applyLinterIgnoreToFolder.luau` to recursively apply ignore rules to every file.

1. Run `lune run tools\applyLinterIgnoreToFolder.luau <PATH>`

## Todos

[ ] Fix issues with CFrames not working after the first iteration of the generator.
[ ] Allow for publishing of the game
