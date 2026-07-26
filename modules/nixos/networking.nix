{ pkgs, ... }:

{
  boot.extraModprobeConfig = ''
    options iwlwifi disable_11be=1 power_save=0
  '';

  networking.networkmanager.plugins = with pkgs; [
    networkmanager-fortisslvpn
    networkmanager-l2tp
    networkmanager-openconnect
    networkmanager-openvpn
    networkmanager-vpnc
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
