{ pkgs, ... }:

{
  # IPv6 is disabled: the router advertises DNS AAAA records but no usable
  # default v6 route, so half the clients (e.g. Noctalia's internal HTTP)
  # hang on IPv6 connects instead of falling back to IPv4.
  networking.enableIPv6 = false;

  boot.extraModprobeConfig = ''
    options iwlwifi disable_11be=1 power_save=0
  '';

  networking.networkmanager.plugins = with pkgs; [
    networkmanager-l2tp
    networkmanager-openconnect
    networkmanager-openvpn
  ];

  networking.networkmanager.wifi.powersave = false;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.gvfs.enable = true;
  services.udisks2.enable = true;

  environment.systemPackages = with pkgs; [
    cifs-utils
    nmap
    openvpn
    samba
    wireguard-tools
  ];
}
