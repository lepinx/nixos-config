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
  # Deploy sin construir en el host: la notebook copia el closure con
  # --target-host, y algunos paths se generan localmente y no vienen firmados
  # por cache.nixos.org (AdGuardHome.yaml es el primero que apareció), así que
  # el daemon del destino los rechaza por `require-sigs`. lucho ya está en
  # wheel y puede sudo-ear, por lo que marcarlo trusted no amplía su poder
  # real sobre esta VM; sólo evita tener que construir acá cada vez.
  nix.settings.trusted-users = [ userName ];

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
    runCheck = true;
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
    runCheck = true;
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
      # tunnels. Only 80/443 is forwarded from the WAN, and the forward is just
      # the transport: Pangolin decides per resource what is public and what
      # requires authentication. Everything else stays LAN/VPN-only.
      allowedTCPPorts = [
        22
        80
        443
        # Hermes Agent dashboard backend (LAN-only, no WAN forward)
        9119
        # Samba (solo SMB directo; sin NetBIOS 137-139)
        445
        # AdGuard Home: el resolver DNS de la LAN (TCP para respuestas grandes)
        53
      ];
      # 53/udp es el camino normal de las consultas; el modulo de AdGuard solo
      # abre el puerto de su UI (3000), asi que 53 se abre a mano.
      allowedUDPPorts = [
        53
        51820
      ];
    };
    nftables.enable = true;
  };

  # Samba: recursos de la familia sobre los datasets NFS del Proxmox. Cada
  # recurso fuerza usuario/grupo para que las escrituras SMB no dependan del
  # login y el resultado coincida con el propietario del dataset (fuerza
  # UID/GID a través de NFS, sin pelear con los permisos 0700/2775).
  services.samba = {
    enable = true;
    settings = {
      global = {
        security = "user";
        "server min protocol" = "SMB2";
      };

      # Carpeta personal con una sola URL para todos: Samba sustituye %U por
      # el usuario autenticado, asi cada quien aterriza en su propia carpeta
      # sin saber como se llama su share. Si el dataset no existe la conexion
      # falla, en vez de caer en el dataset padre y exponer a los demas.
      # No se usa [homes]: deriva la ruta del home de /etc/passwd y el home de
      # lucho es /home/lucho (ahi viven sus authorized_keys de sshd).
      personal = {
        path = "/mnt/tank/familia/%U";
        "valid users" = "@familia";
        "read only" = "no";
        browseable = "yes";
      };

      lucho = {
        path = "/mnt/tank/familia/lucho";
        "valid users" = "lucho";
        "read only" = "no";
        browseable = "no";
        "force user" = "lucho";
        "force group" = "lucho";
      };

      ricardo = {
        path = "/mnt/tank/familia/ricardo";
        "valid users" = "ricardo";
        "read only" = "no";
        browseable = "no";
        "force user" = "ricardo";
        "force group" = "ricardo";
      };

      mariaelena = {
        path = "/mnt/tank/familia/mariaelena";
        "valid users" = "mariaelena";
        "read only" = "no";
        browseable = "no";
        "force user" = "mariaelena";
        "force group" = "mariaelena";
      };

      compartido = {
        path = "/mnt/tank/familia/compartido";
        "valid users" = "@familia";
        "read only" = "no";
        # Sin force user: cada miembro escribe con su propio uid y el bit
        # setgid del dataset mantiene el grupo familia (3010).
        "force group" = "familia";
      };
    };
  };

  # Immich: fotos de la familia sobre /tank/immich (nas:nas en el Proxmox).
  # El módulo trae su propio Postgres (en /var/lib/postgresql, disco local de
  # la VM) y Redis por socket unix; no se monta ninguna base de datos en NFS.
  services.immich = {
    enable = true;
    # El nixpkgs fijado trae immich 2.7.5, marcado inseguro (sin más updates;
    # la 3.x vive en unstable), así que tomamos el paquete del input
    # nixpkgs-unstable que ya tiene el flake. Es un override SOLO del paquete:
    # el módulo sigue siendo el del nixpkgs estable fijado. Borrar esta línea
    # cuando el nixpkgs fijado lleve la 3.x.
    package = inputs.nixpkgs-unstable.legacyPackages.x86_64-linux.immich;
    # Escucha en la LAN (el módulo solo abre 2283/tcp con openFirewall).
    host = "0.0.0.0";
    port = 2283;
    openFirewall = true;
    mediaLocation = "/mnt/tank/immich";
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

  # AdGuard Home: el resolver DNS de la LAN, nativo (era un contenedor en la
  # torre vieja). El modulo abre solo el puerto de la UI; 53/tcp y 53/udp se
  # abren a mano en el firewall de arriba.
  #
  # La credencial de administracion NO se declara aca: el repo es publico y
  # docs/secrets.md prohibe publicar hashes de contrasena. Con mutableSettings
  # el primer arranque usa el asistente web y el usuario queda en
  # /var/lib/AdGuardHome/AdGuardHome.yaml, que sobrevive a los rebuilds; el
  # merge declarativo solo pisa las claves que este archivo define.
  services.adguardhome = {
    enable = true;
    host = "0.0.0.0";
    port = 3000;
    openFirewall = true;
    mutableSettings = true;
    settings = {
      dns = {
        upstream_dns = [
          "1.1.1.1"
          "9.9.9.9"
        ];
        bootstrap_dns = [
          "9.9.9.9"
          "1.1.1.1"
        ];
      };
      # El DHCP lo hace el router; habilitarlo aca pediria CAP_NET_RAW de mas.
      dhcp.enabled = false;
    };
  };

  # Identidad única para el NAS: los mismos uid/gid existen en el Proxmox, así
  # los archivos de /tank no cambian de dueño al cruzar NFS. lucho reutiliza la
  # cuenta admin (uid fijado para que no dependa de la asignación automática);
  # ricardo y mariaelena son cuentas de servicio sin shell ni home, solo para
  # autenticarlos en Samba.
  users.groups.nas.gid = 3000;
  # Immich's module creates this user itself; pinning the ids keeps the NFS
  # dataset ownership on the Proxmox stable (NFS matches numbers, not names).
  users.groups.immich.gid = 3011;
  users.users.immich.uid = 3011;
  users.groups.ricardo.gid = 3002;
  users.groups.mariaelena.gid = 3003;
  # Grupo del recurso compartido: /tank/familia/compartido es nas:familia 2775.
  # El grupo "lucho" (gid 1000) existe solo para que las escrituras SMB del
  # recurso privado de lucho salgan como 1000:1000, igual que en el Proxmox.
  users.groups.lucho.gid = 1000;
  users.groups.familia = {
    gid = 3010;
    members = [ "lucho" "ricardo" "mariaelena" ];
  };

  users.users.nas = {
    isSystemUser = true;
    uid = 3000;
    group = "nas";
    description = "NAS service account (Samba/Immich)";
  };

  users.users.ricardo = {
    isSystemUser = true;
    uid = 3002;
    group = "ricardo";
    description = "Cuenta NAS (Samba) para ricardo";
  };

  users.users.mariaelena = {
    isSystemUser = true;
    uid = 3003;
    group = "mariaelena";
    description = "Cuenta NAS (Samba) para mariaelena";
  };

  users.users.${userName} = {
    isNormalUser = true;
    # Fijado: en el Proxmox /tank/familia/lucho es 1000:1000, y Samba depende
    # de que este uid sea determinista.
    uid = 1000;
    extraGroups = [ "wheel" ];
  };
}
