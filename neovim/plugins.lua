return require('packer').startup(function()
  -- Packer can manage itself
  use { 'wbthomason/packer.nvim' }

  use { 'kyazdani42/nvim-web-devicons' }

  use { 'vim-airline/vim-airline' }
  use { 'vim-airline/vim-airline-themes' }

  -- Colorscheme
  use { 'sonph/onehalf', rtp = 'vim' }

  -- Underlines the word under the cursor
  use { 'itchyny/vim-cursorword' }

  use { 'lukas-reineke/indent-blankline.nvim' }

  -- Surroundings: parentheses, brackets, quotes, XML tags, and more
  use { 'tpope/vim-surround' }

  -- Allow repeating surrounds with --.--
  use { 'tpope/vim-repeat' }

  use { 'godlygeek/tabular' }

  -- Unified clipboard for vim and tmux
  use { 'tmux-plugins/vim-tmux-focus-events' }
  use { 'roxma/vim-tmux-clipboard' }

  -- Support for .tmux.conf
  use { 'tmux-plugins/vim-tmux' }

  -- Seemless navigation between vim and tmux
  use { 'christoomey/vim-tmux-navigator' }

  -- Autoclose brackets
  use { 'Raimondi/delimitMate' }

  -- Syntax highlight
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }

  -- Formatting for specific cases
  use { 'vim-autoformat/vim-autoformat' }

  -- Snippets
  use { 'SirVer/ultisnips' }

  -- Snippets are separated from the engine. Add this if you want them:
  use { 'honza/vim-snippets' }
  -- Support for some custom snippets
  use { 'reconquest/vim-pythonx' }

  -- Code completion
  use { 'neoclide/coc.nvim', branch = 'release' }

  use { 'lervag/vimtex' }
end)

