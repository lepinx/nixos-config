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
    cargoLock = {
      lockFile = "${inputs.glab-tui}/Cargo.lock";
    };
    src = inputs.glab-tui;
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
