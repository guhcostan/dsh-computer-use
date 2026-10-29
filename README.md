# dsh-computer-use

**Desktop computer use for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness).**
A DSH profile bundle that connects the shared computer-use service to the installed
[Cua Driver](https://github.com/trycua/cua) daemon — the mode that can draw the **visible agent
cursor**, capture the desktop and drive native apps.

`MIT` · `DSH 0.2.1-rc.3` · `macOS` (Cua Driver is cross-platform; this bundle is verified on macOS)

---

## What you get

| Tool namespace | Capability |
|---|---|
| `mcp__cua-driver-mcp__*` | screenshots, window/AX snapshots, click, type, key presses, scroll, drag, app launch/close, browser helpers, recording, **agent cursor overlay** |

The agent sees the same Cua Driver tool catalog it would get from the vendor MCP server:
62+ tools covering screenshots, accessibility trees, pointer/keyboard input, app lifecycle,
clipboard, window management and browser automation.

Because the driver runs as a separate GUI application (`CuaDriver.app`), it owns the macOS
permissions and can paint the agent cursor on screen. The in-process "native" provider cannot:
a headless Node host receives `facility_unavailable` for cursor overlay operations even when
screenshots and input work.

## Requirements

1. **DeepSeek Harness 0.2.1-rc.3** (desktop app or any DSH profile with tools + system prompt).
2. **Cua Driver installed** (the standalone app + CLI). Follow the upstream installer; verify:

   ```sh
   cua-driver --version    # e.g. cua-driver 0.23.2
   cua-driver doctor
   ```

3. **macOS permissions for `CuaDriver.app`** (not for DSH): Accessibility and Screen
   Recording. Grant and verify with:

   ```sh
   cua-driver permissions grant
   ```

   The command asks CuaDriver to request the grants, then verifies live capture. Granting
   permissions to the DSH app is not enough for this provider; the daemon is its own app
   identity (`com.trycua.driver`).

## Install

The supported installation path is the DSH **Plugin Manager**; it installs the bundle,
resolves its dependencies and registers it as a profile bundle layer.

1. Clone this repository:

   ```sh
   git clone https://github.com/guhcostan/dsh-computer-use.git
   ```

2. In a DSH session, ask the agent to install the bundle from that absolute path
   (`plugin_manager` with `action: install_bundle` and the repository directory as `target`).

3. Open a **new chat**. Sessions created before the bundle activated do not receive the new
   tool namespace.

> The bundle declares `@deepseek-ai/dsh-computer-use` and
> `@deepseek-ai/dsh-experimental-computer-use-cua-driver-mcp` as dependencies. Exactly one
> computer-use provider can be mounted per profile; do not add the native provider too.

## Configuration

The bundle uses `command: cua-driver` from `PATH`. If DSH was launched from Finder/Launchpad
and the CLI is not on `PATH`, override the row in your profile's `cordis.patch.yml`; an
override replaces the whole `config`:

```yaml
- id: computer-use-cua-driver-mcp
  name: '@deepseek-ai/dsh-experimental-computer-use-cua-driver-mcp'
  config:
    command: /Users/you/.local/bin/cua-driver
    args: ['mcp']
    toolCallTimeoutMs: 180000
```

The daemon auto-starts on first use (macOS MCP proxy). Stop it with `cua-driver stop`.

## Verify

1. Open a new chat and ask: *"Take a screenshot of my desktop."*
2. The agent should call `mcp__cua-driver-mcp__get_desktop_state` and show the image.
3. Ask for a simple interaction, e.g. *"Open Calculator and click 7 + 8 =."* You should see
   the magenta agent cursor move on screen (the default `cua.default` theme).

Optional preflight:

```sh
sh scripts/check.sh
```

## How it works

DeepSeek Harness composes a profile from ordered patch layers. This is a
**configuration-only bundle**: `package.json` declares `dsh.bundle.patch` and
`cordis.patch.yml` inserts two rows — the computer-use seam and the installed-Cua-Driver MCP
provider. The provider spawns `cua-driver mcp`; on macOS that is a proxy for the standalone
`CuaDriver.app` daemon, which owns permissions, execution and the cursor overlay.

```
dsh-computer-use/
├── package.json          # dsh.bundle.patch + dependencies + display metadata
├── cordis.patch.yml      # the two rows inserted into the profile
├── locale/{en,zh}.json   # Plugin Manager title/description
├── icon.svg              # bundle icon
└── scripts/check.sh      # Cua Driver / permission preflight
```

## Known driver quirks (0.23.2)

These come from Cua Driver, not from the bundle; they are documented so you do not chase them.
All of them were reproduced while validating this bundle against DSH 0.2.1-rc.3 + Cua Driver 0.23.2:

- **Session label** — do not pass the literal `session: "implicit"`: the tool rejects it
  (`session 'implicit' has ended`). Omit `session` and the current transport's implicit
  session is used.
- `get_agent_cursor_state` fails output-schema validation while `position` is `null`, and on
  some builds returns only the summary line without `theme`/`position`/`visibility`. Enable
  the cursor first, and use `get_cursor_position` if you need a position read-back.
- `move_cursor` rejects `target` combined with `scope`; use `scope: "window"` plus the legacy
  `pid` / `window_id` fields.
- Window-scope `x`/`y` are window-local screenshot pixels. On a 2x Retina display the overlay
  placement reported by the driver can diverge in x while y matches; treat positions as
  approximate and verify visually.
- `set_agent_cursor_theme` rejects ids that are not installed and does not list valid ones;
  the default theme is `cua.default`.
- `get_config` may return only the header on some builds.
- `list_windows` may return only a count (`Found N window(s)`) without window records on
  macOS; use `get_accessibility_tree` for exact `pid` / `window_id`.
- Inline images from `get_desktop_state` can fail with `Maximum call stack size exceeded`;
  pass `screenshot_out_file` to write the PNG to disk instead.

## Version compatibility

DSH prereleases require plugins whose peer dependencies match the running build exactly.
This release is pinned to **0.2.1-rc.3**. When your DSH updates, update the two dependency
versions in `package.json` to the same build and reinstall the bundle.

## License

[MIT](./LICENSE) © 2026 Gustavo Costa

This bundle wires packages published by DeepSeek and the Cua Driver published by Trycua.
Their licenses and support terms are their own; this repository contains only the
composition, documentation and artwork.
