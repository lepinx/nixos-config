-- LSP wiring that does not belong to a single language.
--
-- Every server binary comes from Nix: the user profile in modules/home/editors.nix
-- or a project devShell. Mason therefore has nothing to install, and it stays
-- disabled instead of loaded with a dead `:Mason` command.
--
-- Language-specific settings live in one file per language (go.lua, nix.lua,
-- csharp.lua, sql.lua, ...) so adding a language never edits a shared file.
return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      -- just-lsp: formats and completes justfiles. Project-rooted on .git, which
      -- is what the recipe files in these repos need.
      opts.servers.just = {}
    end,
  },
}
