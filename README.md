# firefox-safari-glass

A dark, see-through, Safari-style theme for Firefox on Linux. Built for Hyprland (works with any compositor that blurs translucent windows).

Firefox paints its window translucent; your compositor blurs whatever is behind it.

## What it does

- **Safari layout** — toolbar on top with a centered, rounded URL field (address centered when idle, blue focus ring), tabs underneath at equal widths with centered titles and a hover-only close button on the left. The tab row hides when only one tab is open.
- **Glass** — the whole window is one dark translucent sheet. Menus, panels and the URL dropdown are a little more solid so they stay readable. The new tab page is see-through too.
- **Mac-like behaviour** — rubber-band overscroll, macOS scroll physics, two-finger swipe back/forward, pinch to zoom.
- **Websites stay opaque** so text is readable — only Firefox's own UI is glass.

## Install

One command — works with **Firefox** and **LibreWolf**:

```sh
curl -fsSL https://raw.githubusercontent.com/EnvyMeAdams/firefox-safari-glass/main/install.sh | bash
```

That's it. The script:
- finds the default profile of every Firefox / LibreWolf it can see (native installs and Flatpak, old `~/.mozilla` / `~/.librewolf` and newer `~/.config` locations)
- closes the browser if it's running and **brings your tabs back** when it reopens
- keeps your own CSS (restored on uninstall) and **merges** into an existing `user.js` instead of replacing it (arkenfox etc. stay intact)
- reopens the browser

Re-run the same command any time to update.

Prefer to read it first? Clone and run it locally:

```sh
git clone https://github.com/EnvyMeAdams/firefox-safari-glass.git
cd firefox-safari-glass
./install.sh --help
```

| Option | |
|---|---|
| `-b, --browser firefox\|librewolf\|all` | only install into one browser (default: all found) |
| `-p, --profile PATH` | use a specific profile folder (see `about:profiles`) |
| `--no-restart` | close the browser if needed, but don't reopen it |
| `-u, --uninstall` | remove the theme and reset the prefs it changed |

With the curl one-liner, pass options after `bash -s --`, e.g. `... | bash -s -- --browser librewolf`.

### LibreWolf note

LibreWolf turns on fingerprinting protection by default, which makes websites think you're in light mode. The browser UI is still dark glass; only page content is affected. If you want dark websites too, use the Dark Reader extension rather than turning the protection off.

## Compositor

Hyprland only needs blur on:

```ini
decoration {
    blur {
        enabled = true
    }
}
```

Don't add an opacity window rule for Firefox — that would fade page content too.

## One-time toolbar setup

⋯ → More tools → Customize toolbar:

`sidebar · back · forward · [flexible space] · URL field · [flexible space] · downloads · +`

Keep the **+** (new tab) button in the toolbar, since the tab row hides when there's a single tab.

## Tweaking

Variables at the top of `chrome/userChrome.css`:

| Variable | What it controls |
|---|---|
| `--sg-tint` | Window glass — raise the alpha for less see-through |
| `--sg-popup` | Menus, panels, URL dropdown |
| `--sg-accent` | Accent colour (Safari blue by default) |
| `--sg-url-width` | Max width of the URL field |

To always show the tab row, delete the block commented *"Safari hides the tab row when only one tab is open"*.

`user.js` is re-applied at every launch — change prefs there, not in `about:config`.

## Troubleshooting

**Window is opaque** — make sure Firefox was fully quit before installing, and that blur is enabled in your compositor. Some Firefox releases have regressed transparency (e.g. [bug 2045222](https://bugzilla.mozilla.org/show_bug.cgi?id=2045222)); the theme already sets `body` transparent to work around that one.

**Vertical tabs** — the layout assumes horizontal tabs; `user.js` sets `sidebar.verticalTabs` to `false`.

## Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/EnvyMeAdams/firefox-safari-glass/main/install.sh | bash -s -- --uninstall
```

Puts back any CSS you had before, removes the `user.js` block, and resets the prefs the theme set.

## License

[MIT](LICENSE) — use it, fork it, remix it.
