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
    inputs.hermes-agent.nixosModules.default
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
  sops.secrets.telegram_bot_token = { };
  sops.secrets.telegram_allowed_users = { };
  sops.secrets.nan_builders_api_key = { };
  sops.secrets.hermes_dashboard_user = { };
  sops.secrets.hermes_dashboard_password = { };

  # Hermes reads its .env from HERMES_HOME; the module copies this file there
  # at activation, so the values never pass through the Nix store in plaintext.
  sops.templates."hermes.env" = {
    content = ''
      TELEGRAM_BOT_TOKEN=${config.sops.placeholder.telegram_bot_token}
      TELEGRAM_ALLOWED_USERS=${config.sops.placeholder.telegram_allowed_users}
      NAN_BUILDERS_API_KEY=${config.sops.placeholder.nan_builders_api_key}
      HERMES_DASHBOARD_BASIC_AUTH_USERNAME=${config.sops.placeholder.hermes_dashboard_user}
      HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${config.sops.placeholder.hermes_dashboard_password}
    '';
  };

  # The old host ran the container with HERMES_DASHBOARD=1 and Traefik pointed
  # at port 9119, so "dashboard" reproduces the current behaviour. It listens
  # on the LAN only; --insecure is required because the desktop/CLI client
  # cannot authenticate against a remote backend yet (upstream limitation).
  services.hermes-agent = {
    enable = true;
    backend = {
      mode = "dashboard";
      host = "0.0.0.0";
      port = 9119;
      extraArgs = [ "--insecure" ];
    };
    environmentFiles = [ config.sops.templates."hermes.env".path ];
  };

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
    # Los inodos que devuelve NFS cambian cuando el automount remonta la ruta,
    # así que sin esto restic considera que todos los archivos cambiaron y
    # re-lee los 22 GB cada noche en lugar de hacer un incremental.
    extraBackupArgs = [ "--ignore-inode" ];

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
        # Hermes Agent dashboard backend (LAN-only, no WAN forward)
        9119
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
