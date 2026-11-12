{
  config,
  pkgs,
  repoPath,
  ...
}:
let
  # Language servers, formatters and linters the editor drives. They live in the
  # user profile instead of `programs.neovim.extraPackages`: that wrapper made
  # the binaries reachable only by the wrapped nvim, so `shfmt`, `prettier`,
  # `taplo` or `tree-sitter` were missing in a terminal. Same store paths, so
  # the closure does not grow — only the PATH does. The Nix/just/shell linting
  # set also lives in development.nix; Nix dedupes the overlap.
  editorTools = with pkgs; [
    biome
    csharp-ls
    curl
    deadnix
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
    package-version-server
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
in
{
  home.packages = editorTools;

  xdg.configFile = {
    "nvim/lua".source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/nvim/lua";
    "nvim/colors".source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/nvim/colors";
    "nvim/stylua.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/nvim/stylua.toml";
  };

  programs = {
    neovim = {
      enable = true;
      defaultEditor = false;
      viAlias = true;
      vimAlias = true;
      extraLuaPackages = luaPkgs: [
        luaPkgs.rest-nvim
      ];
      initLua = ''
        vim.env.NVIM_RENDER_MARKDOWN_PLUGIN = "${pkgs.vimPlugins.render-markdown-nvim}"
        vim.opt.runtimepath:prepend("${repoPath}/configs/nvim")
        dofile("${repoPath}/configs/nvim/init.lua")
      '';
    };
  };

}
