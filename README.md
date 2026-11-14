# firefox-safari-glass

A dark, see-through, Safari-style theme for Firefox on Linux. Built for Hyprland (works with any compositor that blurs translucent windows).

Firefox paints its window translucent; your compositor blurs whatever is behind it.

## What it does

- **Safari layout** — toolbar on top with a centered, rounded URL field (address centered when idle, blue focus ring), tabs underneath at equal widths with centered titles and a hover-only close button on the left. The tab row hides when only one tab is open.
- **Glass** — the whole window is one dark translucent sheet. Menus, panels and the URL dropdown are a little more solid so they stay readable. The new tab page is see-through too.
- **Mac-like behaviour** — rubber-band overscroll, macOS scroll physics, two-finger swipe back/forward, pinch to zoom.
- **Websites stay opaque** so text is readable — only Firefox's own UI is glass.

## Install

Quit Firefox completely, then:

```sh
git clone https://github.com/EnvyMeAdams/firefox-safari-glass.git
cd firefox-safari-glass
./install.sh                 # auto-detects your default profile
./install.sh /path/to/profile  # or point it at one (see about:profiles)
```

The installer:
- finds the profile in `~/.config/mozilla/firefox` (Firefox 147+) or `~/.mozilla/firefox`
- backs up any existing `userChrome.css` / `userContent.css`
- **merges** its prefs into an existing `user.js` (arkenfox etc. stay intact) inside a marked block, so re-running it is safe

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

Delete `chrome/userChrome.css` and `chrome/userContent.css` from your profile (or restore the `.bak-*` copies), and remove the `// >>> safari-glass >>>` block from `user.js`.

## License

[MIT](LICENSE) — use it, fork it, remix it.
