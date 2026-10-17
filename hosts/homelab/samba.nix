_:

{
  # SMB is LAN-only: openFirewall adds 445/139 TCP and 137/138 UDP, reachable
  # only from behind the router.
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "homelab";
        security = "user";
      };

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

}
