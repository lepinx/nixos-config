{
  hostName,
  userName,
  inputs,
  config,
  ...
}:

{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ../../modules/nixos/profiles/server.nix
    inputs.sops-nix.nixosModules.sops
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

  # NAS: datasets de ZFS exportados por NFS desde el Proxmox (192.168.1.10).
  # _netdev para no depender del orden de arranque de red; nofail + automount
  # para que un Proxmox caído no impida que la VM bootee.
  fileSystems."/mnt/tank/familia" = {
    device = "192.168.1.10:/tank/familia";
    fsType = "nfs";
    options = [
      "nfsvers=4.2"
      "_netdev"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "timeo=600"
      "retrans=2"
    ];
  };

  fileSystems."/mnt/tank/immich" = {
    device = "192.168.1.10:/tank/immich";
    fsType = "nfs";
    options = [
      "nfsvers=4.2"
      "_netdev"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "timeo=600"
      "retrans=2"
    ];
  };

  # The VM's own SSH host key is used as its age identity, so no separate
  # key file is needed.
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.defaultSopsFile = ../../sops/homelab.yaml;
  sops.secrets.restic_password = { };

  # The restic systemd service runs as root, so the SSH alias must live in the
  # system-wide client config rather than a per-user ~/.ssh/config.
  programs.ssh.extraConfig = ''
    Host tower
      HostName 192.168.1.50
      Port 2222
      User lucho
      IdentityFile /home/lucho/.ssh/id_ed25519_tower
      IdentitiesOnly yes
      StrictHostKeyChecking accept-new
  '';

  services.restic.backups.homelab = {
    repository = "sftp:tower:/srv/data/restic/homelab";
    passwordFile = config.sops.secrets.restic_password.path;
    initialize = true;
    paths = [
      "/etc"
      "/home"
      "/var/lib"
    ];
    exclude = [
      "/var/cache"
      "/var/tmp"
      "*.tmp"
      "lost+found"
    ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
  };

  # Backup independiente para los datos del NAS: si el Proxmox o el montaje
  # NFS caen, el job de configuración (homelab) sigue funcionando. El repo ya
  # existe (lo inicializó el job homelab) y la retención ya la aplica su
  # pruneOpts sobre todo el repositorio, así que aquí no se podan.
  services.restic.backups.nas = {
    repository = "sftp:tower:/srv/data/restic/homelab";
    passwordFile = config.sops.secrets.restic_password.path;
    paths = [
      "/mnt/tank/familia"
      "/mnt/tank/immich"
    ];
    exclude = [
      "*.tmp"
      "lost+found"
    ];
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
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

  # Identidad única para el NAS: el mismo uid/gid existe en el Proxmox, así los
  # archivos de /tank no cambian de dueño al cruzar NFS.
  users.groups.nas.gid = 3000;

  users.users.nas = {
    isSystemUser = true;
    uid = 3000;
    group = "nas";
    description = "NAS service account (Samba/Immich)";
  };

  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
