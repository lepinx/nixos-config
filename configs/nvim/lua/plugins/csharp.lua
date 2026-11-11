-- C# / .NET support.
--
-- The LSP binary (csharp-ls) comes from the Nix wrapper of Neovim, defined in
-- modules/home/editors.nix. The .NET SDK is project-scoped: run `nix develop`
-- from the repository, which provides dotnet-sdk_10 through its flake.nix.
-- Mason stays disabled, so nothing here depends on :Mason.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        csharp_ls = {},
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "c_sharp" },
    },
  },
}
