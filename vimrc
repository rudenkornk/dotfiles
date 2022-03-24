" Required for Vundle and other settings
set nocompatible

" Required for Vundle
filetype off

" Set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" Alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" Let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" Use dev icons from powerline fonts
Plugin 'ryanoasis/vim-devicons'

" Status line
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'

" Colorscheme
Plugin 'sonph/onehalf', { 'rtp': 'vim' }

" Underlines the word under the cursor
Plugin 'itchyny/vim-cursorword'

" Surroundings: parentheses, brackets, quotes, XML tags, and more
Plugin 'tpope/vim-surround'

" Unified clipboard for vim and tmux
Plugin 'tmux-plugins/vim-tmux-focus-events' " Only for vim < 8.2.2345
Plugin 'roxma/vim-tmux-clipboard'

" Support for .tmux.conf
Plugin 'tmux-plugins/vim-tmux'

" Seemless navigation between vim and tmux
Plugin 'christoomey/vim-tmux-navigator'

" Autoclose brackets
Plugin 'Raimondi/delimitMate'

" Code completion
Plugin 'neoclide/coc.nvim'

call vundle#end()

" Required for Vundle
filetype plugin on
" To ignore plugin indent changes, comment next line:
filetype indent on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

" Also required for coc.nvim
set encoding=utf-8

set t_Co=256
if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

syntax enable

" Allow backspacing over everything in insert mode.
set backspace=indent,eol,start

" keep more lines of command line history
set history=1000

" Show column number
set ruler

" Show typing command
set showcmd

" Display completion matches in a status line
set wildmenu
set wildmode=longest:list

" Show a few lines of context around the cursor.  Note that this makes the
" text scroll if you mouse-click near the start or end of the window.
set scrolloff=1

" Highlight search results
set hlsearch

" Show search results immediately
set incsearch

" Show @@@ in the last line if it is truncated.
set display=truncate

" Relative number lines on the left
set number " relativenumber

" Disable formatting in insert mode
" Unfortunatelly this breaks autocomplete with tab, so it is not permanently
" enabled
"set paste
nnoremap <leader>vp :set invpaste<CR>


" Insert spaces instead of tabs
set smarttab
set tabstop=2
set shiftwidth=2
set expandtab

set wrap

"set foldmethod=syntax
"set foldlevel=5

set notimeout nottimeout

" Support russian with specific keyboard layouts
if !empty(expand(glob("/usr/share/vim/vim*/keymap/rnk-russian-qwerty.vim")))
  set keymap=rnk-russian-qwerty
  set iminsert=0
  set imsearch=0
  highlight lCursor guifg=NONE guibg=Cyan
endif

" Fix CTRL-arrow behaviour
" https://unix.stackexchange.com/a/1764
" But this breaks exit from insert mode
"map <ESC>[1;5D] <C-Left>
"map <ESC>[1;5C] <C-Right>
"map! <ESC>[1;5D] <C-Left>
"map! <ESC>[1;5C] <C-Right>



" Set custom cursor in different modes
" 1 - blinking rectangle
" 2 - normal rectangle
" 3 - blinking underscore
" 4 - normal underscore
" 5 - blinking vertical bar
" 6 - normal vertical bar
let &t_SI.="\e[5 q" " Insert mode
let &t_SR.="\e[4 q" " Replace mode
let &t_EI.="\e[6 q" " Normal mode

" Setup netrw file explorer
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 15

" Setup gdb
packadd termdebug
let g:termdebug_wide = 163
nnoremap <leader>db :Break<CR>
nnoremap <leader>dr :call TermDebugSendCommand('run')<CR>
nnoremap <leader>dn :call TermDebugSendCommand('next')<CR>
nnoremap <leader>ds :call TermDebugSendCommand('step')<CR>
nnoremap <leader>df :call TermDebugSendCommand('finish')<CR>
nnoremap <leader>dc :call TermDebugSendCommand('continue')<CR>
nnoremap <leader>du :call TermDebugSendCommand('up')<CR>
nnoremap <leader>dd :call TermDebugSendCommand('down')<CR>
nnoremap <leader>dt :call TermDebugSendCommand('backtrace')<CR>
" Invoke normal mode in terminal with double Esc
tnoremap <Esc><Esc> <C-\><C-n>

" Setup vim-airline and color theme
" section_z notation:
" %p% -- relative position in percent
" %l -- line number
" %L -- total lines
" %c -- column number
colorscheme onehalfdark
let g:Powerline_symbols='unicode'
let g:airline_powerline_fonts = 1
let g:airline_section_z = "%l/%L %p%%"
let g:airline_theme='onehalfdark'
set background=dark
set cursorline

" Setup vim-tmux-navigator
let g:tmux_navigator_no_mappings = 1
nnoremap <silent> <C-w>h :TmuxNavigateLeft<cr>
nnoremap <silent> <C-w>j :TmuxNavigateDown<cr>
nnoremap <silent> <C-w>k :TmuxNavigateUp<cr>
nnoremap <silent> <C-w>l :TmuxNavigateRight<cr>
nnoremap <silent> <C-w>p :TmuxNavigatePrevious<cr>



highlight RedundantSpacesAndTabs ctermbg=red guibg=red
match RedundantSpacesAndTabs /\(\s\+$\|\t\+\)/

