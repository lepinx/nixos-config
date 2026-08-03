{
  pkgs,
  pkgsUnstable,
  ...
}:

let
  heliumVersion = "0.15.1.1";
  heliumSrc = pkgs.fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${heliumVersion}/helium-${heliumVersion}-x86_64.AppImage";
    hash = "sha256-qz3w+nnvBgkpHT3E34dv4DvFuYlyzTAyg9tPYJFWs3o=";
  };
  heliumContents = pkgs.appimageTools.extractType2 {
    pname = "helium";
    version = heliumVersion;
    src = heliumSrc;
  };
  helium = pkgs.appimageTools.wrapType2 {
    pname = "helium";
    version = heliumVersion;

    src = heliumSrc;

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
    podman-compose
    pkgsUnstable.opencode
  ];

  programs = {
    firefox.enable = true;
  };
}
