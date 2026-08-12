{ pkgs, ... }:

let
  yaziDevices = pkgs.writeShellApplication {
    name = "yazi-devices";
    runtimeInputs = with pkgs; [
      coreutils
      fzf
      gawk
      gnused
      jq
      udisks2
      util-linux
      yazi
    ];
    text = builtins.readFile ../../configs/scripts/yazi-devices.sh;
  };

  yaziTrash = pkgs.writeShellApplication {
    name = "yazi-trash";
    runtimeInputs = with pkgs; [
      coreutils
      fzf
      less
      trash-cli
      yazi
    ];
    text = builtins.readFile ../../configs/scripts/yazi-trash.sh;
  };
in
{
  programs.yazi.enable = true;

  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never";
  };

  home.packages = with pkgs; [
    trash-cli
    udiskie
    yaziDevices
    yaziTrash
  ];

  xdg.configFile = {
    "yazi/keymap.toml".source = ../../configs/yazi/keymap.toml;
    "yazi/plugins/smart-cd.yazi/main.lua".source = ../../configs/yazi/plugins/smart-cd.yazi/main.lua;
  };
}
