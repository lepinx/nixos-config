# Declarative PWA launchers for Helium (Chromium fork).
#
# Helium auto-generates chrome-*.desktop entries in ~/.local/share/applications
# when a web app is installed. On NixOS those entries are broken:
#   - Exec points to the bare AppRun in /nix/store, which fails outside the
#     appimageTools wrapper environment (missing libglib, etc.).
#   - They may carry NoDisplay=true, hiding them from launchers.
#
# These user-owned entries override that: they use the system wrapper
# (/run/current-system/sw/bin/helium, stable across package updates) and are
# never rewritten by the browser. Icons are vendored in assets/pwa-icons/ and
# installed into the hicolor icon theme under our own "pwa-" namespace, so they
# never collide with the chrome-* icons the browser manages (and deletes when
# a web app is uninstalled from the browser).
{ lib, ... }:

let
  heliumExec = "/run/current-system/sw/bin/helium";

  pwa = {
    youtube-music = {
      name = "YouTube Music";
      appId = "cinhimbnkkaeohfgghhklpknlkffjgod";
      categories = [ "Network" "Audio" ];
      comment = "YouTube Music as an app";
    };
    whatsapp-web = {
      name = "WhatsApp Web";
      appId = "hnpfjngllnobngcgfapefoaidbinmjnm";
      categories = [ "Network" "InstantMessaging" ];
      comment = "WhatsApp Web as an app";
    };
    telegram-web = {
      name = "Telegram Web";
      appId = "ibblmnobmgdmpoeblocemifbpglakpoi";
      categories = [ "Network" "InstantMessaging" ];
      comment = "Telegram Web as an app";
    };
  };
in
{
  xdg.dataFile = lib.mapAttrs' (name: _: lib.nameValuePair
    "icons/hicolor/256x256/apps/pwa-${name}.png"
    { source = ../../assets/pwa-icons/pwa-${name}.png; }
  ) pwa;

  xdg.desktopEntries = lib.mapAttrs (name: cfg: {
    type = "Application";
    name = cfg.name;
    comment = lib.mkDefault cfg.comment;
    exec = "${heliumExec} --profile-directory=Default --app-id=${cfg.appId}";
    icon = "pwa-${name}";
    terminal = false;
    categories = cfg.categories;
    settings.StartupWMClass = "crx_${cfg.appId}";
    startupNotify = true;
  }) pwa;
}
