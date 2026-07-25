{ lib, pkgs, ... }:

{
  home.sessionVariables = {
    DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
    EDITOR = "nvim";
    TERMINAL = "ghostty";
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
    NIXOS_OZONE_WL = "1";
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
        "text/html" = [ "google-chrome.desktop" ];
        "x-scheme-handler/http" = [ "google-chrome.desktop" ];
        "x-scheme-handler/https" = [ "google-chrome.desktop" ];
        "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
        "message/rfc822" = [ "thunderbird.desktop" ];
        "application/x-extension-eml" = [ "thunderbird.desktop" ];
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
