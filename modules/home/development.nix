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
    # Out-of-store so gentle-ai's imports and edits land back in the repo.
    file.".pi/gentle-ai/profiles.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/pi/gentle-ai/profiles.json";
    };

    # alt+up/down for prompt navigation: gentle-pi's todo panel owns
    # ctrl+shift+up/down, and this override also silences the conflict warnings.
    file.".pi/agent/keybindings.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/pi/agent/keybindings.json";
    };

    # settings.json is owned by the pi runtime (packages list, extension
    # opt-outs, tuiMode): gentle-pi's postinstall replaces it with atomic
    # rename and refuses any symlink, so it must stay a regular mutable file.
    # The repo copy is the reference; seedPiSettings seeds fresh installs.

    file.".pi/agent/mcp.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/pi/agent/mcp.json";
    };

    file.".pi/agent/skills/oss-fork" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/pi/agent/skills/oss-fork";
    };

    file.".pi/agent/themes/noctalia.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/pi/agent/themes/noctalia.json";
    };

    file.".pi/gentle-ai/models.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/pi/gentle-ai/models.json";
    };

    file.".pi/gentle-ai/persona.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/pi/gentle-ai/persona.json";
    };

    file.".pi/gentle-ai/vim.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/pi/gentle-ai/vim.json";
    };

    file.".pi/gentle-ai/background-subagents.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/pi/gentle-ai/background-subagents.json";
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
      pkgs.glab
      pkgs.pi-coding-agent
      pkgs.codex
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
    ];
  };

  # Seed the mutable pi settings on machines where the file does not exist
  # yet (fresh installs). Existing files are never touched: the pi runtime
  # owns this file from then on. Skipped during dry runs.
  home.activation.seedPiSettings = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ "''${DRY_RUN:-}" != 1 ] && [ ! -e "$HOME/.pi/agent/settings.json" ]; then
      install -Dm600 "${repoPath}/configs/pi/agent/settings.json" "$HOME/.pi/agent/settings.json"
      echo "seeded ~/.pi/agent/settings.json from repo"
    fi
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
