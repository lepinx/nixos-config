-- TypeScript / React. The LazyVim lang.typescript extra brings vtsls (picked in
-- options.lua) plus the plugins and filetype hooks.
--
-- What the extra does not do is enable the ESLint server, and that one matters
-- here: it reads the repository's own eslint.config.js and reports those findings
-- as diagnostics, so the editor and `pnpm verify` agree instead of disagreeing.
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      opts.servers.eslint = {
        settings = {
          -- Flat config: let the server find the nearest config from the file
          -- itself instead of assuming the buffer's cwd.
          workingDirectories = { mode = "auto" },
        },
      }
    end,
  },
}
