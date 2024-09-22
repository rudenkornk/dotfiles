-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- mitigate the long clipboard loading issue
vim.g.clipboard = require("config.clipboard")
