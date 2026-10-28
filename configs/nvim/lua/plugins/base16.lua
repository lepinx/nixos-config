-- matugen.setup() is applied by configs/nvim/colors/matugen.lua when that
-- colorscheme is selected; running it here unconditionally would pollute
-- every other colorscheme (it rewrites base16 groups at startup).
return { 'RRethy/base16-nvim' }
