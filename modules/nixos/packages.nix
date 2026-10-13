{ pkgs, ... }:

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
  environment.systemPackages = with pkgs; [
    helium
    nautilus
    podman-compose
  ];

  programs = {
    firefox.enable = true;
  };
}
