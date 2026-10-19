{
  pkgs,
  hostName,
  userName,
  ...
}:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    inherit hostName;
    networkmanager.enable = true;
  };

  users.users.${userName} = {
    isNormalUser = true;
    description = userName;
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  programs.fish.enable = true;

  # Gateway URL is untracked (public repo): one line, wss://<host>/api/ws.
  programs.fish.interactiveShellInit = ''
    if test -f $HOME/.config/hermes/gateway-url
      set -gx HERMES_TUI_GATEWAY_URL (cat $HOME/.config/hermes/gateway-url | string trim)
    end
  '';

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
}
