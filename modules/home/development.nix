{
  config,
  pkgs,
  repoPath,
  ...
}:
let
  provisionAgentTools = pkgs.writeShellApplication {
    name = "provision-agent-tools";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      git
      gnutar
      gzip
      nodejs
    ];
    text = builtins.readFile ../../scripts/provision-agent-tools.sh;
  };
in
{
  home = {
    # The agent lives entirely under ~/.gentle-shell: the launcher's isolated
    # home holds Pi's state, and GENTLE_AI_HOME points the gentle-ai CLI (and
    # the launcher's own child process) at the same tree, so nothing is written
    # to ~/.pi.

    # alt+up/down for prompt navigation: gentle-pi's todo panel owns
    # ctrl+shift+up/down, and this override also silences the conflict warnings.
    file.".gentle-shell/agent/keybindings.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/gentle-shell/agent/keybindings.json";
    };

    # settings.json is owned by the pi runtime (packages list, extension
    # opt-outs, tuiMode): gentle-pi's postinstall replaces it with atomic
    # rename and refuses any symlink, so it must stay a regular mutable file.
    # The repo copy is the reference; seedAgentSettings seeds fresh installs.

    # mcp.json, persona.json and profiles.json are seeded regular files for the
    # same reason: gentle-ai's install and sync pipelines refuse to read a
    # symlink they are about to inject into (`refusing to read symlink`), which
    # broke both `gentle-shell setup` and `gentle-ai sync`. profiles.json earns
    # its place here the same way: `/gentle:profiles` rewrites it with an atomic
    # rename, which replaces the symlink with a regular file, so every profile
    # edit landed outside the repo and the next activation with `force = true`
    # restored the symlink over it and discarded the edit. Nix seeds them; the
    # agent owns them from then on, and the repo copy stays the fresh-machine
    # reference.

    file.".gentle-shell/agent/skills/oss-fork" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/gentle-shell/agent/skills/oss-fork";
    };

    file.".gentle-shell/gentle-ai/models.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/gentle-shell/gentle-ai/models.json";
    };

    file.".gentle-shell/gentle-ai/vim.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/gentle-shell/gentle-ai/vim.json";
    };

    file.".gentle-shell/gentle-ai/background-subagents.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/gentle-shell/gentle-ai/background-subagents.json";
    };

    # One Pi, owned by the Gentle Shell product. The bundled install keeps its Pi
    # under ~/.gentle-shell/current (a stable symlink that `gentle-shell upgrade`
    # moves), so this exposes that binary instead of letting nixpkgs ship a
    # second, independently-versioned one. gentle-ai needs a `pi` on PATH (it runs
    # `pi install npm:gentle-pi`), and now it gets the same binary the launcher
    # runs: no drift, and no "which Pi am I in" ambiguity.
    #
    # A wrapper, not a symlink: node_modules/.bin/pi is an npm shim that derives
    # its target from $0, so following a symlink from ~/.local/bin makes it load
    # ~/.local/@earendil-works/... and fail with MODULE_NOT_FOUND. Invoking the
    # bundled entry with the launcher's own node is what the launcher itself does.
    file.".local/bin/pi" = {
      executable = true;
      text = ''
        #!/bin/sh
        root="$HOME/.gentle-shell"
        entry="$root/current/node_modules/@earendil-works/pi-coding-agent/dist/bundle/cli.js"
        if [ ! -f "$entry" ]; then
          for c in "$HOME/.local/share/agent-runtime/npm/bin/pi" "/etc/profiles/per-user/$USER/bin/pi"; do
            [ -x "$c" ] && exec "$c" "$@"
          done
          echo "pi: no Pi installation found ($entry); run the Gentle Shell installer" >&2
          exit 127
        fi
        node_bin="$root/runtime/node-24.21.0/bin/node"
        [ -x "$node_bin" ] || node_bin="$(command -v node)"
        exec "$node_bin" "$entry" "$@"
      '';
    };

    sessionVariables = {
      NPM_CONFIG_PREFIX = "$HOME/.local/share/agent-runtime/npm";
      NPM_CONFIG_CACHE = "$HOME/.cache/agent-runtime/npm";
      # Keep the gentle-ai CLI and the launcher on one tree: without this the
      # CLI recreates ~/.pi/gentle-ai even when the agent home lives elsewhere.
      GENTLE_AI_HOME = "$HOME/.gentle-shell/gentle-ai";
      # A hand-run pi or `gentle-ai sync` resolves the *agent* home from this
      # variable, not from GENTLE_AI_HOME; the launcher sets it only for its own
      # children. Without it the CLI still writes into ~/.pi/agent.
      PI_CODING_AGENT_DIR = "$HOME/.gentle-shell/agent";
    };

    sessionPath = [
      "/etc/profiles/per-user/$USER/bin"
      # The bundled gentle-shell launcher lives in ~/.local/bin and must win over
      # the legacy npm global; fish builds PATH explicitly, see shell.nix.
      "$HOME/.local/bin"
      "$HOME/.local/share/agent-runtime/npm/bin"
    ];

    packages = with pkgs; [
      direnv
      gh
      pkgs.glab
      just-lsp
      jujutsu
      lazydocker
      lazygit
      nodejs
      nil
      just
      nix-direnv
      nixfmt
      deadnix
      statix
      shellcheck
      sql-formatter
    ];
  };

  # Seed the mutable agent settings on machines where the file does not exist
  # yet (fresh installs). Existing files are never touched: the pi runtime owns
  # this file from then on. Skipped during dry runs.
  home.activation.seedAgentSettings = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    seed() {
      if [ "''${DRY_RUN:-}" != 1 ] && [ ! -e "$2" ]; then
        install -Dm600 "$1" "$2"
        echo "seeded $2 from repo"
      fi
    }
    seed "${repoPath}/configs/gentle-shell/agent/settings.json" "$HOME/.gentle-shell/agent/settings.json"
    seed "${repoPath}/configs/gentle-shell/agent/mcp.json" "$HOME/.gentle-shell/agent/mcp.json"
    seed "${repoPath}/configs/gentle-shell/gentle-ai/persona.json" "$HOME/.gentle-shell/gentle-ai/persona.json"
    seed "${repoPath}/configs/gentle-shell/gentle-ai/profiles.json" "$HOME/.gentle-shell/gentle-ai/profiles.json"
  '';

  # Install missing mutable tools on first login; existing installations and
  # user-managed upgrades are never replaced by a Nix generation.
  systemd.user.services.provision-agent-tools = {
    Unit = {
      Description = "Provision missing mutable agent tools";
      After = [ "network-online.target" ];
      StartLimitIntervalSec = 0;
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${provisionAgentTools}/bin/provision-agent-tools";
      Restart = "on-failure";
      RestartSec = "5min";
    };
    Install.WantedBy = [ "default.target" ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
