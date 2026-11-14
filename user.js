// >>> safari-glass >>>
// Load userChrome.css / userContent.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Transparency (Wayland/Hyprland)
user_pref("browser.tabs.allow_transparent_browser", true);
user_pref("widget.transparent-windows", true);
user_pref("widget.wayland.opaque-region.enabled", false);
user_pref("gfx.webrender.all", true);
user_pref("mozilla.widget.use-argb-visuals", true);   // only matters on X11

// No client-side titlebar/window buttons
user_pref("browser.tabs.inTitlebar", 0);

// Dark everywhere
user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("browser.theme.toolbar-theme", 0);
user_pref("browser.theme.content-theme", 0);
user_pref("layout.css.prefers-color-scheme.content-override", 0);

// Compact density, horizontal tabs (the layout assumes tabs on top)
user_pref("browser.compactmode.show", true);
user_pref("browser.uidensity", 1);
user_pref("sidebar.verticalTabs", false);

// Safari-ish behaviour
user_pref("browser.urlbar.trimURLs", true);                 // hide http://
user_pref("browser.urlbar.trimHttps", true);                // hide https:// too
user_pref("apz.overscroll.enabled", true);                  // rubber-band scrolling
user_pref("general.smoothScroll.msdPhysics.enabled", true); // macOS-like scroll feel
user_pref("widget.disable-swipe-tracker", false);           // two-finger swipe back/forward
user_pref("apz.gtk.touchpad_pinch.enabled", true);          // pinch to zoom
// <<< safari-glass <<<
