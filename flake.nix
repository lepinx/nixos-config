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

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    stylix = {
      url = "git+https://github.com/nix-community/stylix?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "git+https://github.com/ogulcancelik/herdr?ref=refs/tags/v0.6.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
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
        }:
        nixpkgs.lib.nixosSystem {
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
              home-manager.nixosModules.home-manager
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

      nixosConfigurations = {
        office = mkNixos {
          hostName = "office";
          diskDevice = "/dev/sda";
          modules = [
            ./hosts/office
            inputs.disko.nixosModules.disko
            ./modules/nixos/virtualization.nix
          ];
        };

        workstation = mkNixos {
          hostName = "workstation";
          diskDevice = "/dev/nvme0n1";
          modules = [
            ./hosts/workstation
            inputs.disko.nixosModules.disko
            ./modules/nixos/virtualization.nix
          ];
        };
      };
    };
}
