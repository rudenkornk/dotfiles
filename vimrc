set nocompatible

" Allow backspacing over everything in insert mode.
set backspace=indent,eol,start

" keep more lines of command line history
set history=200

" Show column number
set ruler

" Show typing command
set showcmd

" display completion matches in a status line
set wildmenu
set wildmode=longest:list,full

" Show a few lines of context around the cursor.  Note that this makes the
" text scroll if you mouse-click near the start or end of the window.
set scrolloff=1

" Highlight search results
set hlsearch

" Show search results immediately
set incsearch

" Show @@@ in the last line if it is truncated.
set display=truncate

syntax on

highlight RedundantSpaces ctermbg=red guibg=red
match RedundantSpaces /\s\+$/

" Relative number lines on the left
set number relativenumber

" Fix different appearance in tmux vs raw terminal
set background=dark

" Support russian with specific keyboard layouts
set keymap=rnk-russian-qwerty
set iminsert=0
set imsearch=0
highlight lCursor guifg=NONE guibg=Cyan

