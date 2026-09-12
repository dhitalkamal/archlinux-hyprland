-- ============================================================================
--  Hyprland Lua config  —  ~/.config/hypr/hyprland.lua
--
--  Hyprland loads THIS file in preference to hyprland.conf. We moved to Lua so
--  we can use layer_rule blur (frosted-glass bar/launcher/notifications) and
--  window_rule matching, which are Lua-only since Hyprland 0.55.
--
--  ROLLBACK: delete this file (`rm ~/.config/hypr/hyprland.lua`) and Hyprland
--  falls back to the hyprland.conf next login.
-- ============================================================================

local home = os.getenv("HOME")

-- Wallpaper-derived palette (written by wall-theme). Fallback if not present.
local C = {
    background    = "rgba(151819ff)",
    backgroundAlt = "rgba(222628ff)",
    foreground    = "rgba(ebeeefff)",
    accent        = "rgba(73c0deff)",
    accent2       = "rgba(de73c3ff)",
    accent3       = "rgba(c5de73ff)",
}
local ok, loaded = pcall(dofile, home .. "/.config/hypr/colors.lua")
if ok and type(loaded) == "table" then
    for k, v in pairs(loaded) do C[k] = v end
end

-- ---- programs -------------------------------------------------------------
local terminal    = "kitty"
-- toggle: second super+space kills the open wofi instead of stacking a new one
local menu        = "pkill -x wofi || wofi --show drun"

-- ---- monitors -------------------------------------------------------------
-- eDP-1: native 1920x1080@60, scale 1 (true 1:1 pixels, full 1080p workspace)
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })

-- ---- environment ----------------------------------------------------------
hl.env("XCURSOR_THEME", "catppuccin-mocha-dark-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- ---- look & feel ----------------------------------------------------------
hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 8,
        border_size = 1,                          -- minimal, thin border
        col = {
            active_border   = "rgba(7f849cff)",   -- subtle grey (focused)
            inactive_border = "rgba(45475a88)",   -- dim grey (unfocused)
        },
        layout = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        rounding = 16,                       -- rounder = glassier
        active_opacity   = 0.96,
        inactive_opacity = 0.88,
        dim_inactive = true,
        dim_strength = 0.1,
        shadow = {
            enabled = true,
            range = 30,
            render_power = 4,
            color = 0xbb11111b,
            color_inactive = 0x6611111b,
        },
        blur = {
            enabled = true,
            size = 10,                       -- heavier frosted-glass blur
            passes = 4,
            new_optimizations = true,
            xray = true,
            ignore_opacity = true,
            vibrancy = 0.15,
            vibrancy_darkness = 0.05,
            contrast = 1.1,                  -- subtle glass pop
            brightness = 1.0,
            noise = 0.015,                   -- faint frosted texture
            popups = true,
            popups_ignorealpha = 0.2,
        },
    },

    dwindle = { preserve_split = true },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
    },

    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            disable_while_typing = true,
        },
    },

    animations = { enabled = true },
})

-- ---- animation curves + timeline (springy eye-candy) ----------------------
hl.curve("wind",      { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05}  } })
hl.curve("overshot",  { type = "bezier", points = { {0.13, 0.99}, {0.29, 1.1}  } })
hl.curve("smoothOut", { type = "bezier", points = { {0.36, 0},    {0.66, -0.56} } })
hl.curve("smoothIn",  { type = "bezier", points = { {0.25, 1},    {0.5, 1}     } })
hl.curve("liner",     { type = "bezier", points = { {1, 1},       {1, 1}       } })

hl.animation({ leaf = "windows",     enabled = true, speed = 6,   bezier = "overshot",  style = "slide" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 6,   bezier = "overshot",  style = "slide" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 5,   bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5,   bezier = "wind",      style = "slide" })
hl.animation({ leaf = "border",      enabled = true, speed = 10,  bezier = "liner" })
hl.animation({ leaf = "fade",        enabled = true, speed = 6,   bezier = "smoothIn" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,   bezier = "overshot",  style = "slidefade 20%" })

-- ---- touchpad gestures ----------------------------------------------------
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- ---- autostart (runs once when Hyprland starts) ---------------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,ssh")  -- secret store for Chrome/apps (no-op if not installed)
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("quickshell")   -- custom control-center panel (toggled via bar badge)
    hl.exec_cmd("udiskie")
    -- hl.exec_cmd("hypridle")   -- DISABLED — no auto sleep/lock/screen-off on idle
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd(home .. "/.local/bin/wall-restore")   -- restore last-chosen wallpaper (image or video)
    hl.exec_cmd(home .. "/.local/bin/dynamic-workspaces")  -- macos-like dynamic spaces: follow off an emptied workspace
end)

-- ---- keybindings  (macOS-style) -------------------------------------------
--  cmd = SUPER → ⌘ Command (system + app shortcuts)
--  wm  = ALT   → window management (focus / move / workspaces). Was SUPER.
--
--  IMPORTANT: in-app ⌘ shortcuts (⌘C/V/X, ⌘S, ⌘Z, ⌘F, ⌘T …) are produced by
--  keyd (/etc/keyd/default.conf), which rewrites meta+letter → Ctrl+letter
--  BEFORE Hyprland sees it. So any bind on `cmd` must use a key keyd does NOT
--  remap: Space Return Tab ` Escape Q E H digits arrows Print F-keys. That is
--  why every letter-based window/utility bind lives on `wm` (ALT).
local cmd = "SUPER"
local wm  = "ALT"

-- ── System / launching (⌘) ──
hl.bind(cmd .. " + Space",       hl.dsp.exec_cmd(menu))                 -- ⌘Space  → Spotlight (launcher)
hl.bind(cmd .. " + Return",      hl.dsp.exec_cmd(terminal))             -- ⌘Return → terminal
hl.bind(cmd .. " + SHIFT + Return", hl.dsp.exec_cmd(home .. "/.local/bin/dropterm"))  -- SUPER+SHIFT+Return: dropdown terminal
hl.bind(cmd .. " + E",           hl.dsp.exec_cmd(terminal .. " yazi"))  -- SUPER+E -> file manager (yazi in kitty)
hl.bind(cmd .. " + Q",           hl.dsp.window.close())                 -- ⌘Q      → quit / close window
hl.bind(cmd .. " + CTRL + Q",    hl.dsp.exec_cmd("hyprlock"))           -- ⌘⌃Q    → lock screen
hl.bind(cmd .. " + CTRL + Escape",  hl.dsp.exec_cmd([[bash -c 'ans=$(echo -e "Cancel\nReboot" | wofi --dmenu -p "Confirm reboot"); [ "$ans" = Reboot ] && systemctl reboot']]))          -- cmd+ctrl+esc: reboot (confirm)
hl.bind(cmd .. " + SHIFT + Escape", hl.dsp.exec_cmd([[bash -c 'ans=$(echo -e "Cancel\nShut Down" | wofi --dmenu -p "Confirm shutdown"); [ "$ans" = "Shut Down" ] && systemctl poweroff']]))        -- cmd+shift+esc: shutdown (confirm)
hl.bind(cmd .. " + SHIFT + Q",   hl.dsp.exec_cmd("wlogout -b 5 -p layer-shell"))  -- ⌘⇧Q → log-out menu
hl.bind(cmd .. " + D",           hl.dsp.exec_cmd("qs ipc call cc toggle"))        -- ⌘D   → Control Center

-- ── App / window switching (⌘) ──
hl.bind(cmd .. " + Tab",         hl.dsp.window.cycle_next())                -- cmd+Tab       -> next window
hl.bind(cmd .. " + SHIFT + Tab", hl.dsp.window.cycle_next({ prev = true })) -- cmd+shift+Tab -> previous window
hl.bind(cmd .. " + grave",       hl.dsp.exec_raw("focuscurrentorlast"))     -- cmd+grave     -> toggle last window
hl.bind(cmd .. " + H",           hl.dsp.window.move({ workspace = "special:hidden", silent = true }))  -- cmd+H       -> hide window
hl.bind(cmd .. " + SHIFT + H",   hl.dsp.workspace.toggle_special("hidden"))                            -- cmd+shift+H -> peek hidden

-- Screenshots (macOS-style, via ~/.local/bin/screenshot)
-- add CTRL to send to clipboard instead of saving a file, exactly like macOS.
hl.bind(cmd .. " + SHIFT + 3",        hl.dsp.exec_cmd(home .. "/.local/bin/screenshot full file"))    -- whole screen -> file
hl.bind(cmd .. " + CTRL + SHIFT + 3", hl.dsp.exec_cmd(home .. "/.local/bin/screenshot full clip"))    -- whole screen -> clipboard
hl.bind(cmd .. " + SHIFT + 4",        hl.dsp.exec_cmd(home .. "/.local/bin/screenshot region file"))  -- region -> file
hl.bind(cmd .. " + CTRL + SHIFT + 4", hl.dsp.exec_cmd(home .. "/.local/bin/screenshot region clip"))  -- region -> clipboard
hl.bind(cmd .. " + SHIFT + 5",        hl.dsp.exec_cmd(home .. "/.local/bin/screenshot menu"))         -- screenshot menu (macOS cmd+shift+5 toolbar)
hl.bind(cmd .. " + SHIFT + 6",        hl.dsp.exec_cmd(home .. "/.local/bin/screenshot window file"))  -- window -> file (macOS cmd+shift+4 then space)

-- ── Window management: move focus (ALT + arrows / hjkl) ──
hl.bind(wm .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(wm .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(wm .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(wm .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(wm .. " + H",     hl.dsp.focus({ direction = "left" }))
hl.bind(wm .. " + J",     hl.dsp.focus({ direction = "down" }))
hl.bind(wm .. " + K",     hl.dsp.focus({ direction = "up" }))
hl.bind(wm .. " + L",     hl.dsp.focus({ direction = "right" }))

-- ── Move windows (ALT + SHIFT + arrows / hjkl) ──
hl.bind(wm .. " + SHIFT + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(wm .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(wm .. " + SHIFT + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(wm .. " + SHIFT + down",  hl.dsp.window.move({ direction = "d" }))
hl.bind(wm .. " + SHIFT + H",     hl.dsp.window.move({ direction = "l" }))
hl.bind(wm .. " + SHIFT + J",     hl.dsp.window.move({ direction = "d" }))
hl.bind(wm .. " + SHIFT + K",     hl.dsp.window.move({ direction = "u" }))
hl.bind(wm .. " + SHIFT + L",     hl.dsp.window.move({ direction = "r" }))

-- ── Window state (ALT) ──
hl.bind(wm .. " + F",         hl.dsp.window.fullscreen())               -- Alt+F  → fullscreen
hl.bind(wm .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))  -- Alt⇧F → float / tile
hl.bind(wm .. " + P",         hl.dsp.window.pseudo())                   -- dwindle pseudotile
hl.bind(wm .. " + S",         hl.dsp.layout("togglesplit"))             -- dwindle split direction

-- ── Workspaces 1..10 + move-to-workspace (ALT) ──
for i = 1, 10 do
    local key = i % 10
    hl.bind(wm .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(wm .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- ── Desktop switching on ⌘ (Super) 1..5 — digits are NOT remapped by keyd,
--    so Super+number reaches Hyprland directly. (Move-to-workspace stays on
--    Alt+Shift+number so it doesn't collide with ⌘⇧3/4/5 screenshots.) ──
for i = 1, 5 do
    hl.bind(cmd .. " + " .. i, hl.dsp.focus({ workspace = i }))
end

-- macOS-style: SUPER + Left/Right hop to the previous/next existing workspace
-- (e-1/e+1 skip gaps, so they only land on workspaces that actually exist)
hl.bind(cmd .. " + left",  hl.dsp.focus({ workspace = "e-1" }))
hl.bind(cmd .. " + right", hl.dsp.focus({ workspace = "e+1" }))

-- ── Scroll + drag (ALT) ──
hl.bind(wm .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(wm .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(wm .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(wm .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })

-- ── Utilities (ALT) — personal helpers, kept off ⌘ so they dodge keyd ──
hl.bind(wm .. " + V",         hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))  -- clipboard history
hl.bind(wm .. " + A",         hl.dsp.exec_cmd("nwg-drawer -c 7 -is 64 -nocats -nofs"))   -- Launchpad-style app grid
hl.bind(wm .. " + W",         hl.dsp.exec_cmd("waypaper"))                               -- wallpaper picker
hl.bind(wm .. " + SHIFT + W", hl.dsp.exec_cmd(home .. "/.local/bin/wall-theme"))         -- re-theme from wallpaper
hl.bind(wm .. " + SHIFT + N", hl.dsp.exec_cmd(home .. "/.local/bin/wall-next"))          -- next wallpaper
hl.bind(wm .. " + N",         hl.dsp.exec_cmd("swaync-client -t -sw"))                    -- toggle notification center
hl.bind(wm .. " + I",         hl.dsp.exec_cmd(home .. "/.local/bin/settings-menu"))       -- Settings hub
hl.bind(wm .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a"))                          -- color picker (copies hex)
hl.bind(wm .. " + SHIFT + S", hl.dsp.exec_cmd("pkill hyprsunset || hyprsunset -t 3800")) -- toggle night light
hl.bind(wm .. " + SHIFT + C", hl.dsp.exec_cmd(home .. "/.local/bin/caffeine-toggle"))    -- caffeine (keep awake)

-- ── macOS-style extras ──
hl.bind(cmd .. " + slash",        hl.dsp.exec_cmd(home .. "/.local/bin/keybind-help"))   -- ⌘/      → shortcut cheatsheet
hl.bind(cmd .. " + CTRL + Space", hl.dsp.exec_cmd(home .. "/.local/bin/emoji-picker"))   -- ⌘⌃Space → emoji picker
hl.bind(wm  .. " + Print",        hl.dsp.exec_cmd(home .. "/.local/bin/screen-record"))  -- Alt+Print → screen recording toggle

-- ── Screenshots (Print key, kept for muscle memory) ──
hl.bind("Print",         hl.dsp.exec_cmd(home .. "/.local/bin/screenshot region file"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(home .. "/.local/bin/screenshot full file"))

-- ── Media / brightness ──
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),      { locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),       { locked = true, repeating = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true })

-- ---- window rules (re-added; Lua supports class/title matching) -----------
hl.window_rule({ name = "float-dialogs",     match = { title = "^(Open File|Save File)$" }, float = true })

-- ---- layer rules: FROSTED-GLASS BLUR behind bar/launcher/notifications ----
hl.layer_rule({ name = "blur-waybar", match = { namespace = "waybar" }, blur = true, xray = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-wofi",   match = { namespace = "wofi" },   blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-swaync-cc",  match = { namespace = "swaync-control-center" },     blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-swaync-notif", match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-drawer", match = { namespace = "nwg-drawer" }, blur = true, ignore_alpha = 0.1 })
