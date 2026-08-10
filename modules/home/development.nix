{
  inputs,
  pkgs,
  pkgsUnstable,
  ...
}:

let
  glab-tui = pkgs.rustPlatform.buildRustPackage {
    pname = "glab-tui";
    version = "0.8.3";
    src = inputs.glab-tui;
    cargoHash = "sha256-U+VWPG03UAsQQe61NvhflY+FCl5jeo4Jb17tpoZiSdo=";
    doCheck = false;
  };
in
{
  home.packages = with pkgs; [
    pkgsUnstable.codex
    direnv
    gh
    pkgsUnstable.gh-dash
    pkgsUnstable.glab
    glab-tui
    just-lsp
    jujutsu
    lazydocker
    lazygit
    pkgsUnstable.lazysql
    nil
    nixd
    just
    nix-direnv
    nixfmt
    shellcheck
    sql-formatter
    pkgsUnstable.tuicr
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
