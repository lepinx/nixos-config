{ lib, pkgs, ... }:

{
  home.sessionVariables = {
    DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
    EDITOR = "nvim";
    TERMINAL = "ghostty";
    BROWSER = "firefox";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "32";
    NIXOS_OZONE_WL = "1";
    # Noctalia regenerates ~/.config/qt{5,6}ct/colors/noctalia.conf on theme
    # changes; without qtct no Qt app ever reads them (only Qt app: krita, Qt6).
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
        "message/rfc822" = [ "thunderbird.desktop" ];
        "application/x-extension-eml" = [ "thunderbird.desktop" ];
        "application/pdf" = [ "firefox.desktop" ];
        "application/x-pdf" = [ "firefox.desktop" ];
        "image/avif" = [ "org.gnome.Loupe.desktop" ];
        "image/bmp" = [ "org.gnome.Loupe.desktop" ];
        "image/gif" = [ "org.gnome.Loupe.desktop" ];
        "image/heic" = [ "org.gnome.Loupe.desktop" ];
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        "image/png" = [ "org.gnome.Loupe.desktop" ];
        "image/svg+xml" = [ "org.gnome.Loupe.desktop" ];
        "image/tiff" = [ "org.gnome.Loupe.desktop" ];
        "image/webp" = [ "org.gnome.Loupe.desktop" ];
        "video/mp4" = [ "mpv.desktop" ];
        "video/mpeg" = [ "mpv.desktop" ];
        "video/quicktime" = [ "mpv.desktop" ];
        "video/webm" = [ "mpv.desktop" ];
        "video/x-matroska" = [ "mpv.desktop" ];
        "video/x-msvideo" = [ "mpv.desktop" ];
        "video/x-ms-wmv" = [ "mpv.desktop" ];
        "video/x-flv" = [ "mpv.desktop" ];
      };
    };
  };

  xdg.configFile."environment.d/20-podman.conf".text = ''
    DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
  '';

  gtk = {
    enable = true;
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
    theme = {
      name = lib.mkDefault "Adwaita-dark";
      package = lib.mkDefault pkgs.gnome-themes-extra;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = lib.mkDefault 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = lib.mkDefault 1;
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = lib.mkDefault "prefer-dark";
    gtk-theme = lib.mkDefault "Adwaita-dark";
    cursor-theme = lib.mkDefault "Adwaita";
    cursor-size = lib.mkDefault 24;
  };
}
