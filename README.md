# Desaturate Begone CDM

A minimal World of Warcraft addon (Retail, Patch 12.0.0+) that stops the Cooldown Manager from greying out ability icons while they are on cooldown.

## What it does

Blizzard's Cooldown Manager desaturates (greyscales) an icon whenever the associated ability is on cooldown. This addon prevents that, keeping icons at full colour so they remain easy to read at a glance. The cooldown swipe and timer text are unaffected — only the desaturation is suppressed.

## Options

Two independent toggles are available in **Interface → AddOns → Desaturate Begone CDM**:

- **Enable for Essential Cooldowns** — applies to the Essential Cooldowns bar
- **Enable for Utility Cooldowns** — applies to the Utility Cooldowns bar

Both are enabled by default. Settings are saved per account.

## Requirements

- World of Warcraft Retail, Patch 12.0.0 or later
- The built-in `Blizzard_CooldownViewer` addon (enabled by default)

## Installation

1. Copy the `DesaturateBegoneCDM` folder into your `World of Warcraft/_retail_/Interface/AddOns/` directory.
2. Reload or log in. The addon loads automatically alongside the Cooldown Manager.
