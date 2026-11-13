-- Nix support: nil_ls ships in the Nix profile and LazyVim's lang.nix extra
-- brings the plugins and the filetype.
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      -- nil: archive flake inputs automatically instead of prompting "Fetch them
      -- now?" every time an input is missing from the eval cache.
      opts.servers.nil_ls = vim.tbl_deep_extend("force", opts.servers.nil_ls or {}, {
        settings = {
          ["nil"] = {
            nix = {
              flake = { autoArchive = true },
            },
          },
        },
      })
    end,
  },
}
