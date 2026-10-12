{
  config,
  inputs,
  pkgs,
  repoPath,
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
  home = {
    # Versioned copy of the gentle-ai agent-model profiles store, linked
    # out-of-store so edits (and gentle-ai's import) land in the repo. The
    # live file was identical to the tracked copy at adoption time.
    file.".pi/gentle-ai/profiles.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/pi/gentle-ai/profiles.json";
    };

    sessionVariables = {
      NPM_CONFIG_PREFIX = "$HOME/.local/share/agent-runtime/npm";
      NPM_CONFIG_CACHE = "$HOME/.cache/agent-runtime/npm";
    };

    sessionPath = [
      "/etc/profiles/per-user/$USER/bin"
      "$HOME/.local/share/agent-runtime/npm/bin"
      "$HOME/.local/bin"
    ];

    packages = with pkgs; [
      direnv
      gh
      pkgs.gh-dash
      pkgs.glab
      pkgs.pi-coding-agent
      pkgs.codex
      pkgs.opencode
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
      pkgs.tuicr
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
