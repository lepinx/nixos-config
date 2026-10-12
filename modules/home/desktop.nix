{
  config,
  hostName,
  pkgs,
  repoPath,
  ...
}:

let
  umbrielConfig = builtins.readFile ../../configs/umbriel/config.toml;
  umbrielOutputsPath = ../../hosts + "/${hostName}/umbriel-outputs.toml";
  noctaliaUiScale = 0.8;
in
{
  home.packages = with pkgs; [
    alacritty
    bitwarden-cli
    yt-dlp # stream resolution / downloads
    pear-desktop # YouTube Music desktop client (MPRIS for the shell media widget)
    telegram-desktop # official Telegram client
    karere # WhatsApp desktop client (GTK4 wrapper of WhatsApp Web; no official Linux app exists)
    clock-rs
    discord
    ente-auth
    gnome-disk-utility
    ghostty
    file-roller
    inkscape
    krita
    libreoffice
    localsend
    loupe
    (mpv.override {
      scripts = [ pkgs.mpvScripts.mpris ]; # media keys + noctalia media widget for the yt-music plugin
    })
    nerd-fonts.hurmit
    nerd-fonts.jetbrains-mono
    networkmanagerapplet
    pkgs.bruno
    pkgs.dbeaver-bin
    seahorse
    thunderbird
  ];

  xdg = {
    configFile = {
      "autostart/nm-applet.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=NetworkManager Applet
        Hidden=true
        X-GNOME-Autostart-enabled=false
      '';
      "ghostty/config".source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/ghostty/config";
      # Hot-reload link too, so shader iterations do not need a rebuild.
      "ghostty/shaders/cursor_smear.glsl".source =
        config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/ghostty/shaders/cursor_smear.glsl";
      "umbriel/config.toml".text =
        builtins.replaceStrings
          [ "@umbriel_outputs_path@" ]
          [ "${config.xdg.configHome}/umbriel/outputs.toml" ]
          umbrielConfig;
      "umbriel/outputs.toml".source = umbrielOutputsPath;
    };

    # Noctalia reads every file in the config dir and then overlays the state-dir
    # settings.toml, which the Settings UI writes and which always wins. That
    # path must stay writable and outside the Nix store, so it is linked to the
    # tracked file below; a plain source would resolve into the store and the UI
    # would fail to save. Noctalia writes through the symlink and watches the
    # target directory, so UI edits land here and external edits reload live.
    stateFile."noctalia/settings.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/noctalia/settings.toml";
  };

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      accessibility = {
        ui_scale = noctaliaUiScale;
      };
      shell = {
        font_family = "JetBrainsMono Nerd Font";
        telemetry_enabled = false;
        polkit_agent = true;
        umbriel_overview_type_to_launch_enabled = true;
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
          builtin_ids = [
            "ghostty"
            "umbriel"
          ];
          enable_community_templates = true;
          community_ids = [ ];
        };
      };
      wallpaper = {
        enabled = true;
        directory = "~/Pictures/wallpapers";
      };
      backdrop = {
        enabled = true;
        # 0.0 keeps the empty-workspace wallpaper sharp; raise for a blurred
        # backdrop behind windows.
        blur_intensity = 0.0;
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
          "umbriel_companion"
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
        # Umbriel layout per focused workspace / active submap (official
        # noctalia/umbriel-companion plugin; hides itself outside Umbriel
        # sessions).
        umbriel_companion = {
          type = "noctalia/umbriel-companion:bar";
        };
        workspaces = {
          type = "workspaces";
          show_labels = false;
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
