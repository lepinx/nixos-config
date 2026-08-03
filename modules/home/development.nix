{ pkgs, ... }:

{
  home.packages = with pkgs; [
    codex
    direnv
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
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
