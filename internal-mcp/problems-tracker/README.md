# problems-tracker MCP

Internal MCP server for Tom's Cowork sidebar — exposes the open-problems backlog
of `docs/problems/` to live artifacts.

This server is **internal-only**. It does NOT ship with the windyroad plugin
suite (sits outside `packages/`, intentionally not included in the npm
workspaces glob in the root `package.json`).

## Tools

- `get_problems_status` — returns `{timeseries, opens, generated}`.
  - `timeseries`: array of `[date, openCount]` pairs (one per day, forward-filled
    from git rename history of `docs/problems/*.{open,verifying,closed,parked}.md`).
  - `opens`: array of open tickets sorted by WSJF desc, each with id, title,
    reported, priority, wsjf, effort, age (days since reported).
  - `generated`: ISO timestamp.

Optional argument:
- `repoPath` — absolute path to the repo. Defaults to the directory the server
  is run from, walking up to find `.git/`.

## Install

```jsonc
// Cowork MCP config
{
  "mcpServers": {
    "problems-tracker": {
      "command": "node",
      "args": [
        "/Users/tomhoward/Projects/windyroad-claude-plugin/internal-mcp/problems-tracker/server.mjs"
      ]
    }
  }
}
```

After saving, reload Cowork. The tool surfaces as
`mcp__problems-tracker__get_problems_status`.

## Smoke test

```sh
node server.mjs <<'EOF'
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"0"}}}
{"jsonrpc":"2.0","id":2,"method":"tools/list"}
{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_problems_status","arguments":{}}}
EOF
```
