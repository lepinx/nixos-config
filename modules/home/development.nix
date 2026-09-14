{
  inputs,
  pkgs,
  pkgsUnstable,
  userName,
  ...
}:

let
  agentFhs = pkgs.buildFHSEnv {
    name = "agent-runtime";
    targetPkgs =
      _pkgs: with pkgsUnstable; [
        bubblewrap
        go
        nodejs
        pnpm
      ];
    profile = ''
      export GOBIN="$HOME/.local/bin"
      export NPM_CONFIG_PREFIX="$HOME/.local/share/agent-runtime/npm"
      export NPM_CONFIG_CACHE="$HOME/.cache/agent-runtime/npm"
      export PATH="$NPM_CONFIG_PREFIX/bin:$HOME/.local/bin:$PATH"
    '';
    runScript = "bash -l";
  };

  agentShell = pkgs.writeShellApplication {
    name = "agent";
    text = ''
      if [ "$#" -eq 0 ]; then
        exec ${agentFhs}/bin/agent-runtime
      fi
      exec ${agentFhs}/bin/agent-runtime -lc 'exec "$@"' -- "$@"
    '';
  };

  codex = pkgs.writeShellApplication {
    name = "codex";
    text = ''
      exec ${agentFhs}/bin/agent-runtime -lc 'exec /home/${userName}/.local/bin/codex "$@"' -- "$@"
    '';
  };

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
  home.sessionPath = [ "$HOME/.local/bin" ];

  home.file = {
    ".local/bin/pi" = {
      executable = true;
      text = ''
        #!${pkgs.runtimeShell}
        exec ${agentFhs}/bin/agent-runtime -lc 'exec "$NPM_CONFIG_PREFIX/bin/pi" "$@"' -- "$@"
      '';
    };

    ".local/bin/codegraph" = {
      executable = true;
      text = ''
        #!${pkgs.runtimeShell}
        exec ${agentFhs}/bin/agent-runtime -lc 'exec "$NPM_CONFIG_PREFIX/bin/codegraph" "$@"' -- "$@"
      '';
    };
  };

  home.packages = with pkgs; [
    codex
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
    agentShell
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
