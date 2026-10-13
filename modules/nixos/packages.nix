{
  pkgs,
  ...
}:

# TEMPORARY — remove after nixpkgs-unstable fixes typescript-language-server.
# 6.0.2 fails with "hash mismatch in fixed-output derivation ...-pnpm-deps.drv"
# (stale pnpm lockfile hash upstream). Override it with the hash nix reports at
# build time until the fix lands. Delete the overlay and restore the plain
# module header once it is fixed upstream.
let
  heliumVersion = "0.15.1.1";
  heliumSrc = pkgs.fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${heliumVersion}/helium-${heliumVersion}-x86_64.AppImage";
    hash = "sha256-qz3w+nnvBgkpHT3E34dv4DvFuYlyzTAyg9tPYJFWs3o=";
  };
  heliumContents = pkgs.appimageTools.extract {
    pname = "helium";
    version = heliumVersion;
    src = heliumSrc;
  };
  helium = pkgs.appimageTools.wrapAppImage {
    pname = "helium";
    version = heliumVersion;

    src = heliumContents;

    extraInstallCommands = ''
      install -Dm444 ${heliumContents}/helium.desktop $out/share/applications/helium.desktop
      install -Dm444 ${heliumContents}/helium.png $out/share/icons/hicolor/512x512/apps/helium.png
    '';

    meta.mainProgram = "helium";
  };
in
{
  nixpkgs.overlays = [
    (final: prev: {
      typescript-language-server = prev.typescript-language-server.overrideAttrs (old: {
        pnpmDeps = prev.fetchPnpmDeps {
          inherit (old)
            pname
            version
            src
            ;
          pnpm = prev.pnpm_12;
          fetcherVersion = 4;
          hash = "sha256-xR/EF60lVBsITKgH7wCM2wHM46PFQevD51KfCENSUH4=";
        };
      });
    })
  ];

  environment.systemPackages = with pkgs; [
    helium
    nautilus
    podman-compose
  ];

  programs = {
    firefox.enable = true;
  };
}
