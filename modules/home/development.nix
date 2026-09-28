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
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.local/share/agent-runtime/npm";
    NPM_CONFIG_CACHE = "$HOME/.cache/agent-runtime/npm";
  };

  home.sessionPath = [
    "/etc/profiles/per-user/$USER/bin"
    "$HOME/.local/share/agent-runtime/npm/bin"
    "$HOME/.local/bin"
  ];

  home.packages = with pkgs; [
    direnv
    gh
    pkgsUnstable.gh-dash
    pkgsUnstable.glab
    pkgsUnstable.pi-coding-agent
    pkgsUnstable.codex
    pkgsUnstable.opencode
    glab-tui
    just-lsp
    jujutsu
    lazydocker
    lazygit
    nodejs
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
