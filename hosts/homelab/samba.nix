_:

{
  # SMB is LAN-only. `openFirewall` adds ports 445/139 (TCP) and 137/138 (UDP)
  # to the firewall. This host sits behind the LAN router, so those ports are
  # not reachable from the WAN even though the merged allowlist also contains
  # the explicit public ports (80/443 TCP, 51820 UDP).
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "homelab";
        security = "user";
      };

      # One share per user subvolume.
      lucho = {
        path = "/srv/data/lucho";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "lucho";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  # Post-install steps:
  #   1. Create a Samba password per user: sudo smbpasswd -a lucho
  #   2. Additional users need: (a) a Btrfs subvolume created during pre-install
  #      staging on the data disk (not in disko.nix), (b) a share here, (c) an
  #      smbpasswd entry.
  #   Btrfs qgroup quotas are a documented runtime follow-up.
}
