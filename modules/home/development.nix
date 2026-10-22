{
  config,
  pkgs,
  repoPath,
  ...
}:
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

    # Out-of-store so pi config and extension opt-outs land back in the repo.
    file.".pi/agent/settings.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/pi/agent/settings.json";
    };

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
      difftastic
      shellcheck
      sql-formatter
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
