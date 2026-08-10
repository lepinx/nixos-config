{
  config,
  hostName,
  lib,
  pkgs,
  pkgsUnstable,
  repoPath,
  ...
}:

let
  ghosttyConfig = builtins.readFile ../../configs/ghostty/config;
  ghosttyFontSizes = {
    workstation = 9;
    office = 13;
  };
  ghosttyFontSize = ghosttyFontSizes.${hostName} or 9;
  niriConfig = builtins.readFile ../../configs/niri/config.kdl.in;
  niriOutputsPath = ../../hosts + "/${hostName}/niri-outputs.kdl";
  niriHostBindsPath = ../../hosts + "/${hostName}/niri-host.kdl";
  niriHostBinds =
    if builtins.pathExists niriHostBindsPath then builtins.readFile niriHostBindsPath else "";
  noctaliaUiScales = {
    workstation = 0.8;
    office = 0.95;
  };
  noctaliaUiScale = noctaliaUiScales.${hostName} or 0.8;
  bitwardenFieldCopy = pkgs.writeShellApplication {
    name = "bitwarden-field-copy";
    runtimeInputs = with pkgs; [
      config.programs.noctalia.package
      coreutils
      jq
      libnotify
      rbw
      wl-clipboard
    ];
    text = builtins.readFile ../../configs/scripts/bitwarden-field-copy.sh;
  };
  niriNoctaliaFallback = pkgs.writeText "noctalia-niri-fallback.kdl" ''
    layout {
        focus-ring {
            active-color "#8f8f8f"
            inactive-color "#3f3f3f"
            urgent-color "#cc4444"
        }

        shadow {
            color "#0007"
        }
    }
  '';
in
{
  home.packages = with pkgs; [
    alacritty
    bitwarden-cli
    bitwardenFieldCopy
    clock-rs
    ente-auth
    gnome-disk-utility
    ghostty
    file-roller
    inkscape
    krita
    libreoffice
    localsend
    loupe
    mpv
    nerd-fonts.hurmit
    nerd-fonts.jetbrains-mono
    networkmanagerapplet
    pkgsUnstable.bruno
    pkgsUnstable.dbeaver-bin
    seahorse
    thunderbird
  ];

  xdg.configFile = {
    "autostart/nm-applet.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=NetworkManager Applet
      Hidden=true
      X-GNOME-Autostart-enabled=false
    '';
    "ghostty/config".text =
      builtins.replaceStrings [ "font-size = 9" ] [ "font-size = ${toString ghosttyFontSize}" ]
        ghosttyConfig;
    "niri/config.kdl".text =
      builtins.replaceStrings
        [
          "@niri_outputs_path@"
          "@niri_host_binds@"
        ]
        [
          "${config.xdg.configHome}/niri/outputs.kdl"
          niriHostBinds
        ]
        niriConfig;
    "niri/outputs.kdl".source = niriOutputsPath;
  };

  home.activation.ensureNoctaliaThemeTargets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    niri_theme="${config.xdg.configHome}/niri/noctalia.kdl"

    if [ ! -e "$niri_theme" ]; then
      $DRY_RUN_CMD install -Dm0644 ${niriNoctaliaFallback} "$niri_theme"
    fi
  '';

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      shell = {
        font_family = "JetBrainsMono Nerd Font";
        ui_scale = noctaliaUiScale;
        telemetry_enabled = false;
        polkit_agent = true;
        niri_overview_type_to_launch_enabled = true;
        launch_apps_as_systemd_services = true;
      };
      lockscreen.enabled = true;
      idle = {
        pre_action_fade_seconds = 2.0;
        behavior = {
          lock = {
            enabled = true;
            timeout = 600;
            action = "lock";
          };
          screen-off = {
            enabled = true;
            timeout = 660;
            action = "screen_off";
          };
          lock-and-suspend = {
            enabled = true;
            timeout = 1800;
            action = "lock_and_suspend";
          };
        };
      };
      battery.warning_threshold = 20;
      theme = {
        mode = "dark";
        source = "wallpaper";
        builtin = "Ayu";
        wallpaper_scheme = "m3-content";
        templates = {
          enable_builtin_templates = true;
          builtin_ids = [ ];
          enable_community_templates = true;
          community_ids = [ ];
          user.niri = {
            input_path = "${repoPath}/configs/noctalia/templates/niri.kdl";
            output_path = "~/.config/niri/noctalia.kdl";
            post_hook = "${lib.getExe pkgsUnstable.niri} msg action load-config-file || true";
          };
        };
      };
      wallpaper = {
        enabled = true;
        directory = "~/Pictures/wallpapers";
      };
      backdrop = {
        enabled = true;
        blur_intensity = 1.0;
        tint_intensity = 0.0;
      };
      weather = {
        enabled = true;
        refresh_minutes = 30;
        unit = "celsius";
        effects = true;
      };
      location = {
        auto_locate = true;
      };
      keybinds = {
        validate = [
          "Return"
          "KP_Enter"
          "Space"
        ];
        cancel = [ "Escape" ];
        left = [
          "Left"
          "Ctrl+H"
        ];
        right = [
          "Right"
          "Ctrl+L"
        ];
        down = [
          "Down"
          "Ctrl+J"
          "Ctrl+N"
        ];
        up = [
          "Up"
          "Ctrl+K"
          "Ctrl+P"
        ];
        tab_next = [ "Tab" ];
        tab_previous = [ "Shift+ISO_Left_Tab" ];
      };
      bar.main = {
        position = "top";
        thickness = 36;
        background_opacity = 0.88;
        margin_ends = 8;
        margin_edge = 6;
        padding = 10;
        widget_spacing = 8;
        font_weight = 600;
        radius = 12;
        shadow = true;
        reserve_space = true;
        capsule = true;
        capsule_fill = "surface_variant";
        capsule_opacity = 0.55;
        capsule_radius = 8.0;
        start = [
          "launcher"
          "workspaces"
        ];
        center = [ "clock" ];
        end = [
          "notifications"
          "network"
          "bluetooth"
          "volume"
          "battery"
          "control-center"
        ];
      };
      widget = {
        workspaces = {
          type = "workspaces";
          display = "none";
        };
        clock = {
          type = "clock";
          format = "{:%a %d %b  %H:%M:%S}";
          tooltip_format = "{:%A, %d de %B de %Y}";
        };
        network = {
          type = "network";
          show_label = false;
        };
        bluetooth = {
          type = "bluetooth";
          show_label = false;
          hide_when_no_connected_device = true;
        };
        volume = {
          type = "volume";
          show_label = false;
        };
        notifications = {
          type = "notifications";
          hide_when_no_unread = true;
        };
      };
      dock = {
        enabled = true;
        position = "bottom";
        icon_size = 44;
        auto_hide = false;
        smart_auto_hide = true;
        reserve_space = false;
        show_running = true;
        show_dots = true;
        show_instance_count = true;
        launcher_position = "start";
      };
      plugins = {
        enabled = [ "noctalia/translator" ];
      };
    };
  };
}
