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
    libreoffice
    localsend
    loupe
    (mpv.override {
      scripts = [ pkgs.mpvScripts.mpris ]; # media keys + noctalia media widget for the yt-music plugin
    })
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
      # Noctalia's alacritty template updates the theme import through this
      # link on theme changes; font and the rest stay user-owned in the repo.
      "alacritty/alacritty.toml".source =
        config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/alacritty/alacritty.toml";
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
        # Toggle-priority until upstream fixes the exclusive-keyboard-layer
        # interaction (noctalia-dev/umbriel#360): with this on, the type-to-launch
        # layer blocks hot corners while the overview is open.
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
      # Dock pins, restored after the v4 -> v5 migration dropped them: v5 does
      # not migrate v4 settings, and the Settings UI rewrote the old state file
      # without [dock]. Declared here so it survives UI rewrites; pin/unpin
      # changes made in the UI still override this.
      theme = {
        mode = "dark";
        source = "wallpaper";
        builtin = "Ayu";
        wallpaper_scheme = "m3-content";
        templates = {
          enable_builtin_templates = true;
          builtin_ids = [
            "alacritty"
            "btop"
            "cava"
            "ghostty"
            "gtk3"
            "gtk4"
            "helix"
            "qt"
            "starship"
            "umbriel"
          ];
          enable_community_templates = true;
          community_ids = [
            "bat"
            "herdr"
            "lazygit"
            "neovim"
            "pi-agent"
            "yazi"
          ];
          # User templates: the community fzf template only ships bash/fish
          # outputs, which nushell cannot source. This renders the same palette
          # mapping to a plain opts file that nushell's config.nu loads at
          # startup when present.
          user = {
            fzf_nu = {
              input_path = "${repoPath}/configs/noctalia-templates/fzf-opts";
              output_path = "$XDG_CONFIG_HOME/fzf/themes/noctalia.opts";
            };
          };
        };
      };
      wallpaper = {
        enabled = true;
        directory = "~/Pictures/wallpapers";
      };
      backdrop = {
        enabled = true;
        # 0.5 blurred backdrop behind windows (was set via the Settings UI and
        # silently reverted to 0.0 when the v5 migration rewrote the state file).
        blur_intensity = 0.5;
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
        # Control-center bar glyph (Tabler icon); v4 setting lost in the v5
        # migration, defaulting back to the noctalia logo.
        control-center = {
          glyph = "brand-qq";
        };
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
        enabled = true;
        position = "bottom";
        icon_size = 32;
        auto_hide = false;
        smart_auto_hide = true;
        reserve_space = false;
        show_running = true;
        show_dots = true;
        show_instance_count = true;
        launcher_position = "start";
        pinned = [
          "org.gnome.Nautilus"
          "thunderbird"
          "discord"
          "com.github.th-ch.youtube-music"
          "helium"
          "firefox"
          "com.mitchellh.ghostty"
          "io.ente.auth"
          "bruno"
          "dbeaver"
          "com.nousresearch.hermes"
          "io.github.tobagin.karere"
          "org.telegram.desktop"
        ];
      };
      plugins = {
        # umbriel-companion and bitwarden were enabled via the v4 state file and
        # dropped by the v5 migration; declared here so they survive UI rewrites.
        enabled = [
          "noctalia/bitwarden"
          "noctalia/translator"
          "noctalia/umbriel-companion"
        ];
      };
    };
  };
}
