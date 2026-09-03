# Game Overview

## What this game is
Star Guardian is a Love2D space shooter built around a simple arcade loop:
menu -> start run -> survive waves -> score and unlock progress -> return to menu.

It currently focuses on desktop first, with mobile touch controls kept as a separate path.

## Core gameplay features
- Side-scrolling vertical shooter
- Wave-based enemy spawning
- Score-driven progression and round transitions
- Multiple ship types with different speed/firepower/HP profiles
- Procedural sound effects and music generated in code
- Persistent save data for language, audio, ship choice, fullscreen, and stats
- Achievement popups during play

## Controls
### Desktop
- A / D: move left and right
- Mouse left button: shoot
- P: pause
- Esc: exit confirmation
- F11: fullscreen toggle
- F1: debug panel toggle

### Mobile
- Touch buttons for movement, shooting, and pause

## UI structure
- Main menu
- Ship select
- Settings
- Language menu
- Debug panel
- Pause prompt
- Exit confirmation
- Round transition
- Game over screen

The visual style uses bright gradients, fractal-like backdrops, and lighter CRT post-processing.

## Save and profile data
The game stores a local profile containing:
- selected language
- fullscreen preference
- volume settings
- selected ship
- high score
- lifetime stats
- per-run stats

## Audio
Audio is procedural only.
There are no wav/ogg assets for gameplay sound effects.
All sound is generated from code in `audio.lua`.

## Language system
Supported languages:
- English
- Chinese (Simplified)
- Japanese

Language resources live under:
- `localization/en.lua`
- `localization/zh_CN.lua`
- `localization/ja.lua`

Fonts are loaded from `resources/fonts/` with fallback support for CJK text.

## Main modules
- `main.lua`: Love2D entry point
- `game.lua`: global state machine and flow controller
- `world.lua`: player, enemies, bullets, particles, stars
- `player.lua`: ship definitions
- `rounds.lua`: wave rules
- `input.lua`: keyboard/mouse/touch input
- `ui.lua`: menu and in-game UI rendering
- `audio.lua`: procedural audio
- `assets.lua`: fonts and asset helpers
- `i18n.lua`: localization lookup
- `meta.lua`: save/load profile data
- `state.lua`: app state helper
- `profile.lua`: profile defaults and merge logic
- `run.lua`: run lifecycle helper
- `app.lua`: lightweight composition root

## Architecture notes
This project is being moved toward a modern split:
- `menu` for navigation
- `run` for gameplay
- `meta` for persistence
- `debug` for inspection and tuning

The goal is to keep state, data, UI, and run logic separated instead of mixing everything inside one file.

## Current limitations
- The project is still in refactor state
- Some systems are transitional and may be replaced
- The current `game.lua` still acts as a bridge while the new architecture is introduced

