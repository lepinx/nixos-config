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

  # This host uses the internal stable nixpkgs instance, so unfree packages
  # are allowed here rather than in the shared core module (the workstation's
  # external unstable instance already carries this in flake.nix).
  nixpkgs.config.allowUnfree = true;

  # This host targets UEFI; keep CSM disabled in the BIOS.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # systemd-based initrd is required for tpm2-device=auto. The SSD is the only
  # LUKS device on this host; the data HDD is left unencrypted and is mounted by
  # filesystem label in the fileSystems block below.
  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices.cryptroot.crypttabExtraOpts = [ "tpm2-device=auto" ];

  # Data HDD: staged with plain Btrfs before install and never reformatted by
  # disko (disko only manages the SSD). The disk is mounted here declaratively by
  # filesystem label, so the staged data survives the install untouched.
  # Per-user subvolumes follow the pattern subvol=<user> mounted at
  # /srv/data/<user>.
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

    # Static LAN address. Gateway and DNS are assumptions to review at install
    # time. Plain NixOS networking (systemd-networkd stays disabled by default).
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
    # Intentionally not in the firewall allowlist: SSH is LAN-only.
    openFirewall = false;
  };

  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
