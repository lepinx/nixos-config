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
    cargoHash = "sha256-IcScQ4vY5Q1BusNSgpwF2EiykACBlFr6GZK3t0V8fV4=";
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
    inputs.sqlit.packages.${pkgs.stdenv.hostPlatform.system}.default
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

  xdg.configFile."sqlit/keymap.json" = {
    force = true;
    source = ../../configs/sqlit/keymap.json;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
