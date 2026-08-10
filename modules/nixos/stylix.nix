{ hostName, pkgs, ... }:

let
  fontSizesByHost = {
    workstation = {
      applications = 11;
      desktop = 11;
      popups = 11;
      terminal = 14;
    };
    office = {
      applications = 13;
      desktop = 13;
      popups = 13;
      terminal = 13;
    };
  };
  cursorSizesByHost = {
    workstation = 24;
    office = 28;
  };
in
{
  stylix = {
    enable = true;
    autoEnable = false;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/ayu-dark.yaml";

    fonts = {
      serif = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      sizes = fontSizesByHost.${hostName} or fontSizesByHost.workstation;
    };

    opacity = {
      applications = 1.0;
      desktop = 0.88;
      popups = 0.92;
      terminal = 0.80;
    };

    cursor = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = cursorSizesByHost.${hostName} or cursorSizesByHost.workstation;
    };

    targets.grub.enable = false;
  };
}
