_:

{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
  };

  # allowUnfree lives per host: hosts using an external nixpkgs.pkgs instance
  # (workstation, unstable) pass it when creating the instance in flake.nix.

  # gentle-pi's npm postinstall only trusts /usr/bin/tar or /bin/tar, which do
  # not exist on NixOS (Gentleman-Programming/gentle-shell#548).
  # Bridge it declaratively until upstream extracts archives in-process.
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/tar - - - - /run/current-system/sw/bin/tar"
  ];

  time.timeZone = "America/Argentina/Cordoba";
  i18n.defaultLocale = "es_AR.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_AR.UTF-8";
    LC_IDENTIFICATION = "es_AR.UTF-8";
    LC_MEASUREMENT = "es_AR.UTF-8";
    LC_MONETARY = "es_AR.UTF-8";
    LC_NAME = "es_AR.UTF-8";
    LC_NUMERIC = "es_AR.UTF-8";
    LC_PAPER = "es_AR.UTF-8";
    LC_TELEPHONE = "es_AR.UTF-8";
    LC_TIME = "es_AR.UTF-8";
  };

  system.stateVersion = "26.05";
}
