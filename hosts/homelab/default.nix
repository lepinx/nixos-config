{
  hostName,
  userName,
  ...
}:

{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ../../modules/nixos/profiles/server.nix
  ];

  nixpkgs.config.allowUnfree = true;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    # The Proxmox host grew the virtio disk; grow the root fs at boot.
    growPartition = true;
  };

  networking = {
    inherit hostName;

    # Static LAN address; ens18 is the virtio NIC on the q35 machine. Gateway
    # and DNS are assumptions to verify at install time.
    interfaces.ens18.ipv4.addresses = [
      {
        address = "192.168.1.11";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.1.1";
    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];

    firewall = {
      enable = true;
      # 22 for LAN SSH, 80/443 for the Pangolin edge, 51820/udp for WireGuard
      # tunnels. The router never forwards these from the WAN, so everything
      # stays LAN/VPN-only.
      allowedTCPPorts = [
        22
        80
        443
      ];
      allowedUDPPorts = [ 51820 ];
    };
    nftables.enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      # Password authentication is an explicit user decision: SSH is LAN/VPN-only
      # and never exposed to the internet. Revisit if the exposure model changes.
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
