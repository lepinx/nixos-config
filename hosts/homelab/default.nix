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
    ./samba.nix
  ];

  nixpkgs.config.allowUnfree = true;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # systemd initrd is required for tpm2-device=auto.
    initrd = {
      systemd.enable = true;
      luks.devices.cryptroot.crypttabExtraOpts = [ "tpm2-device=auto" ];
    };
  };

  # Data HDD: never managed by disko (see disko.nix); mounted by label so the
  # pre-staged Btrfs data survives reinstalls.
  fileSystems."/srv/data/lucho" = {
    device = "/dev/disk/by-label/homelab-data";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "noatime"
      "subvol=lucho"
    ];
  };

  networking = {
    inherit hostName;

    # Static LAN address; gateway/DNS are assumptions to verify at install time.
    interfaces.eno1.ipv4.addresses = [
      {
        address = "192.168.1.50";
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
      # 80/443 for the future Pangolin edge, 51820/udp for Gerbil WireGuard
      # tunnels.
      allowedTCPPorts = [
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
    openFirewall = false;
  };

  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
