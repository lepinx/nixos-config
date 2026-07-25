{ pkgs, ... }:

{
  home.packages = with pkgs; [
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
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
