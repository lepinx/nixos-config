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
      export PATH="$HOME/.local/bin:$NPM_CONFIG_PREFIX/bin:$PATH"
    '';
    runScript = "bash -l";
  };

  agentCommand =
    name: command:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        exec ${agentFhs}/bin/agent-runtime -lc 'exec "$@"' -- ${command} "$@"
      '';
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
    (agentCommand "pi" "/home/${userName}/.local/share/agent-runtime/npm/bin/pi")
    (agentCommand "codegraph" "codegraph")
    (agentCommand "gentle-ai" "/home/${userName}/.local/bin/gentle-ai")
    (agentCommand "engram" "/home/${userName}/.local/bin/engram")
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
