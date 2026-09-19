# @windyroad/wardley

**Wardley Map generation for Claude Code and Codex.** Analyses your codebase and generates a value chain evolution map. *Maturity: Experimental.*

Part of [Windy Road Agent Plugins](../../README.md).

## What It Does

A [Wardley Map](https://learnwardleymapping.com/) visualises your system's components along two axes: value chain (visibility to the user) and evolution (genesis to commodity). This plugin generates one from your source code.

It produces:

- **OWM source file** -- editable source in Online Wardley Maps format
- **SVG and PNG** -- rendered diagram images
- **Markdown analysis** -- written interpretation of the map's strategic implications

## Install

```bash
npx @windyroad/wardley
npx @windyroad/wardley --runtime codex
```

Claude Code remains the default. Use `--runtime codex` or `--runtime both`, then
restart the selected runtime.

## Usage

**Generate or update the Wardley Map:**

```
/wr-wardley:generate
```

Analyses your codebase to identify components, their relationships, and their evolutionary stage, then produces the map and analysis.

**Render an OWM file yourself:**

```bash
wr-wardley-owm-to-svg [input.owm] [output.svg]
```

Installing the plugin puts this command on your `PATH`, and it keeps working
across upgrades -- it resolves to the newest installed version at every call. Use
it rather than a path into the plugin cache: a cache path carries a version
number that changes on every release, so calls written that way break the next
time you update. Defaults are `docs/wardley-map.owm` and `docs/wardley-map.svg`
(plus a `.png` alongside it on macOS).

In Codex, plugin `bin/` directories are not on `PATH`; call
`node <skill-dir>/owm-to-svg.mjs` from the installed skill directory instead.

## Updating and Uninstalling

```bash
npx @windyroad/wardley --update
npx @windyroad/wardley --uninstall
```

## Licence

[MIT](../../LICENSE)
