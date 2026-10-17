{ pkgs, ... }:

{
  boot.extraModprobeConfig = ''
    options iwlwifi disable_11be=1 power_save=0
  '';

  networking = {
    # Router advertises AAAA with no usable v6 route, so clients hang instead of
    # falling back to IPv4.
    enableIPv6 = false;
    networkmanager = {
      plugins = with pkgs; [
        networkmanager-l2tp
        networkmanager-openconnect
        networkmanager-openvpn
      ];
      wifi.powersave = false;
    };
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    gvfs.enable = true;
    udisks2.enable = true;
  };

  environment.systemPackages = with pkgs; [
    cifs-utils
    nmap
    openvpn
    samba
    wireguard-tools
  ];
}
