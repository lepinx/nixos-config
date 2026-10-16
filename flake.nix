{
  description = "Configuración personal de NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    glab-tui = {
      url = "github:rcieri/glab-tui";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Rolling inputs for the workstation host (mkNixos rolling = true). They
    # must come from the same nixpkgs generation as the host's module system:
    # mixing a stable NixOS eval with unstable packages breaks in the
    # modular-services machinery.
    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pinned to the pre-5.3.0 rev: dock smart auto-hide stays pinned visible
    # against umbriel 0-unstable-2026-10-06 (nixpkgs). Unpin once nixpkgs ships
    # a newer umbriel or upstream fixes the smart-hide query:
    #   url = "github:noctalia-dev/noctalia";
    #   nix flake update noctalia
    noctalia = {
      url = "github:noctalia-dev/noctalia/64bc5b178f3f3dc943afb2e6adf1aab79ae76d03";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Rolling: tracks the upstream default branch; `just update` picks up every
    # new herdr commit. Version history: https://github.com/herdrdev/herdr/releases
    herdr = {
      url = "github:herdrdev/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hermes Agent (NousResearch): Desktop app on the workstation via its Home
    # Manager module. Upstream marks Nix support Tier 2 (best-effort) and pins
    # its own nixpkgs — do not add follows, the uv2nix eval depends on them.
    hermes-agent.url = "github:NousResearch/hermes-agent";

  };

  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      home-manager-unstable,
      ...
    }:
    let
      system = "x86_64-linux";
      userName = "lucho";
      repoName = "nixos-config";
      repoPath = "/home/${userName}/${repoName}";
      pkgsUnstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      mkNixos =
        {
          hostName,
          modules,
          enableHomeManager ? true,
          homeProfile ? userName,
          diskDevice ? null,
          # Build the host from nixos-unstable with matching home-manager
          # module inputs instead of the stable release.
          rolling ? false,
        }:
        (if rolling then nixpkgs-unstable else nixpkgs).lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              pkgsUnstable
              hostName
              userName
              repoName
              repoPath
              diskDevice
              ;
          };
          modules =
            modules
            ++ nixpkgs.lib.optionals enableHomeManager [
              (
                if rolling then
                  home-manager-unstable.nixosModules.home-manager
                else
                  home-manager.nixosModules.home-manager
              )
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = {
                    inherit
                      inputs
                      pkgsUnstable
                      hostName
                      userName
                      repoName
                      repoPath
                      diskDevice
                      ;
                  };
                  sharedModules = [ inputs.noctalia.homeModules.default ];
                  users.${userName} = import (./home + "/${homeProfile}");
                };
              }
            ];
        };
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;

      checks.${system}.deadnix =
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.runCommand "deadnix"
          {
            nativeBuildInputs = [ pkgs.deadnix ];
          }
          ''
            deadnix --fail ${./.}
            touch "$out"
          '';

      nixosConfigurations = {
        workstation = mkNixos {
          hostName = "workstation";
          diskDevice = "/dev/nvme0n1";
          rolling = true;
          modules = [
            ./hosts/workstation
            inputs.disko.nixosModules.disko
          ];
        };

        homelab = mkNixos {
          hostName = "homelab";
          enableHomeManager = false;
          diskDevice = "/dev/sda";
          modules = [
            ./hosts/homelab
            inputs.disko.nixosModules.disko
          ];
        };
      };

      # Expose the disk layout as a parameterized function so the Disko CLI can
      # override the target disk at install time with:
      #   disko --flake .#workstation --argstr diskDevice /dev/X --argstr hostName workstation
      # The installed system mounts by partlabel, so it stays device-independent.
      diskoConfigurations.workstation = import ./hosts/workstation/disko.nix;

      # Homelab's disko layout manages only the OS SSD; the CLI can override the
      # target disk at install time with --argstr diskDeviceBoot /dev/X.
      diskoConfigurations.homelab = import ./hosts/homelab/disko.nix;
    };
}
