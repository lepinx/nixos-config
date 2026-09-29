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

  # This host targets UEFI; keep CSM disabled in the BIOS.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # systemd-based initrd is required for tpm2-device=auto. Unlike the
  # workstation, this host has two LUKS devices, so the unlock configuration is
  # declared locally instead of the single-device shared module
  # (modules/nixos/encryption.nix).
  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices = {
    cryptroot.crypttabExtraOpts = [ "tpm2-device=auto" ];
    cryptdata.crypttabExtraOpts = [ "tpm2-device=auto" ];
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
      allowedTCPPorts = [ 80 443 ];
      allowedUDPPorts = [ 51820 ];
    };
    nftables.enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
    # Intentionally not in the firewall allowlist: SSH is LAN-only.
    openFirewall = false;
  };

  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # TODO: add the user's public SSH key before install; none exists yet.
    openssh.authorizedKeys.keys = [ ];
  };
}
