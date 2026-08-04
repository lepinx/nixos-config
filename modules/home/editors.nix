{
  config,
  pkgs,
  repoPath,
  ...
}:

let
  vscodeSecure = pkgs.vscode.override {
    commandLineArgs = "--password-store=gnome-libsecret";
  };
in
{
  home.packages = [
    pkgs.gh-dash
    pkgs.lua-language-server
    pkgs.neovim-remote
    pkgs.package-version-server
    pkgs.zed-editor
  ];

  xdg.configFile = {
    "nvim/lua".source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/nvim/lua";
    "nvim/stylua.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/nvim/stylua.toml";
    "Code/User/settings.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/vscode/settings.json";
    };
    "Code/User/keybindings.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/vscode/keybindings.json";
    };
    "Code/User/snippets/python.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/vscode/snippets/python.json";
    };
    "zed/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/zed/settings.json";
    "zed/keymap.json".source =
      config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/zed/keymap.json";
  };

  programs = {
    vscode = {
      enable = true;
      package = vscodeSecure;
      mutableExtensionsDir = true;
      argvSettings = {
        enable-crash-reporter = false;
        locale = "en";
      };
    };

    helix = {
      enable = true;
      settings = {
        theme = "onedarker";
        editor = {
          line-number = "relative";
          mouse = false;
          bufferline = "multiple";
          cursorline = true;
          true-color = true;
          cursor-shape.insert = "bar";
        };
        keys.normal.esc = [
          "collapse_selection"
          "keep_primary_selection"
        ];
      };
    };

    neovim = {
      enable = true;
      defaultEditor = false;
      viAlias = true;
      vimAlias = true;
      initLua = ''
        vim.env.NVIM_RENDER_MARKDOWN_PLUGIN = "${pkgs.vimPlugins.render-markdown-nvim}"
        vim.opt.runtimepath:prepend("${repoPath}/configs/nvim")
        dofile("${repoPath}/configs/nvim/init.lua")
      '';
      extraPackages = with pkgs; [
        biome
        curl
        delve
        fd
        gcc
        git
        gnumake
        gnutar
        go
        gofumpt
        gopls
        gotools
        gzip
        lua-language-server
        nil
        nixfmt
        nodejs
        prettier
        pyright
        ripgrep
        ruff
        rust-analyzer
        rustfmt
        shfmt
        statix
        stylua
        taplo
        tree-sitter
        typescript-language-server
        unzip
        vtsls
        wget
        vscode-langservers-extracted
      ];
    };
  };

  # VS Code extensions remain mutable and are handled by VS Code Settings Sync.
  # User JSON files are versioned in this repo and linked out-of-store so VS Code
  # can still update them without hitting Nix store read-only paths.
}
