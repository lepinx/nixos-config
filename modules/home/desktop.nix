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
in
{
  home.packages = with pkgs; [
    alacritty
    bitwarden-cli
    yt-dlp
    pear-desktop
    telegram-desktop
    karere # WhatsApp (no official Linux app; GTK4 wrapper of WhatsApp Web).
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
      # Out-of-store: Noctalia's alacritty template rewrites the theme import here.
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

    # The Settings UI writes the state-dir settings.toml and it always wins; it
    # must stay writable, so the tracked file is symlinked out of the store.
    stateFile."noctalia/settings.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/noctalia/settings.toml";
  };

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    # Structural/technical keys only: everything the Settings UI can change
    # lives in the instance-owned settings.toml (configs/noctalia/settings.toml).
    settings = {
      shell = {
        # Toggle-priority until upstream fixes the exclusive-keyboard-layer
        # interaction (noctalia-dev/umbriel#360): with this on, the type-to-launch
        # layer blocks hot corners while the overview is open.
        umbriel_overview_type_to_launch_enabled = true;
        launch_apps_as_systemd_services = true;
      };
      theme.templates.user = {
        # Community fzf template ships bash/fish outputs only; this renders the same
        # palette mapping to an opts file that nushell loads at startup.
        fzf_nu = {
          input_path = "${repoPath}/configs/noctalia-templates/fzf-opts";
          output_path = "$XDG_CONFIG_HOME/fzf/themes/noctalia.opts";
        };
      };
    };
  };
}
