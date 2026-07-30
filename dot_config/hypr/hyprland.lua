local mainMod = "SUPER"

hl.monitor({
    output = "eDP-1",
    mode = "2560x1600@144",
    position = "0x0",
    scale = 1.25,
})

local environment = {
    XCURSOR_THEME = "breeze_cursors",
    XCURSOR_SIZE = "24",
    HYPRCURSOR_THEME = "breeze_cursors",
    HYPRCURSOR_SIZE = "24",
    GDK_BACKEND = "wayland,x11,*",
    QT_QPA_PLATFORM = "wayland;xcb",
    CLUTTER_BACKEND = "wayland",
    MOZ_ENABLE_WAYLAND = "1",
    ELECTRON_OZONE_PLATFORM_HINT = "auto",
    GTK_THEME = "Breeze-Dark",
    QT_QPA_PLATFORMTHEME = "kde",
}

for name, value in pairs(environment) do
    hl.env(name, value)
end

hl.config({
    input = {
        kb_layout = "us,ru",
        kb_variant = ",",
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
        },
    },
    general = {
        gaps_in = 2,
        gaps_out = 0,
        border_size = 0,
    },
    animations = {
        enabled = false,
    },
    decoration = {
        rounding = 0,
        shadow = {
            enabled = false,
        },
        blur = {
            enabled = false,
        },
    },
    misc = {
        vrr = 1,
    },
    cursor = {
        no_hardware_cursors = false,
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

local startupCommands = {
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && sleep 1 && systemctl --user stop xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-desktop-portal && systemctl --user start xdg-desktop-portal-hyprland && sleep 1 && systemctl --user start xdg-desktop-portal",
    "systemctl --user start hyprpolkitagent",
    "mako",
    "waybar",
    "hyprpaper",
    "hypridle",
    "bash -c '[ -x /usr/lib/pam_kwallet_init ] && /usr/lib/pam_kwallet_init'",
    "rm -f /tmp/wob_pipe && mkfifo /tmp/wob_pipe && tail -f /tmp/wob_pipe | wob -c ~/.config/wob/wob.ini",
    "~/.config/hypr/scripts/battery-watch",
    "wl-paste --type text --watch cliphist store",
    "wl-paste --type image --watch cliphist store",
}

hl.on("hyprland.start", function()
    for _, command in ipairs(startupCommands) do
        hl.exec_cmd(command)
    end
end)

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("rofi -show run"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brave"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("hyprlock"))

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))

hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("rofi -modi clipboard:~/.config/hypr/scripts/cliphist-rofi-img -show clipboard -show-icons -theme ~/.config/rofi/cliphist.rasi"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"))

for workspace = 1, 5 do
    hl.bind(mainMod .. " + " .. workspace, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mainMod .. " + SHIFT + " .. workspace, hl.dsp.window.move({
        workspace = workspace,
        follow = true,
    }))
end

hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + CTRL + left", hl.dsp.focus({ workspace = "r-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + SHIFT + mouse:272", hl.dsp.window.resize(), { mouse = true })

local repeatingLocked = { repeating = true, locked = true }
local locked = { locked = true }

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("/home/pa2/.config/hypr/scripts/vol-change +5"), repeatingLocked)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("/home/pa2/.config/hypr/scripts/vol-change -5"), repeatingLocked)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("/home/pa2/.config/hypr/scripts/vol-change mute"), locked)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("/home/pa2/.config/hypr/scripts/bright-change +5%"), repeatingLocked)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("/home/pa2/.config/hypr/scripts/bright-change 5%-"), repeatingLocked)

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd([=[grim -g "$(slurp)" - | tee >(wl-copy) | satty --filename -]=]))
hl.bind("Print", hl.dsp.exec_cmd([=[grim - | tee >(wl-copy) | satty --filename -]=]))

hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("loginctl lock-session && systemctl suspend"), locked)
