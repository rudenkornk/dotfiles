require('packer').startup(function()
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

function exists(name)
  if type(name)~="string" then return false end
  return os.rename(name,name) and true or false
end

-- runtime path workaround, see https://github.com/soywod/himalaya/issues/188#issuecomment-906296736
local packer_compiled = vim.fn.stdpath('config') .. '/plugin/packer_compiled.lua'
if exists(packer_compiled) then
  vim.cmd('luafile'  .. packer_compiled)
end

if packer_plugins and packer_plugins['nvim-treesitter'] and packer_plugins['nvim-treesitter'].loaded then
  require'nvim-treesitter.configs'.setup {
    -- A list of parser names, or "all"
    ensure_installed = {
      "bash",
      "bibtex",
      "c",
      "cmake",
      "cpp",
      "css",
      "dockerfile",
      "fish",
      "html",
      "json",
      "latex",
      "llvm",
      "lua",
      "make",
      "markdown",
      "ninja",
      "perl",
      "python",
      "regex",
      "ruby",
      "toml",
      "vim",
      "yaml",
    },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- List of parsers to ignore installing (for "all")
    ignore_install = { "" },

    highlight = {
      -- `false` will disable the whole extension
      enable = true,

      -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
      -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
      -- the name of the parser)
      -- list of language that will be disabled
      disable = { "" },

      -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
      -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
      -- Using this option may slow down your editor, and you may see some duplicate highlights.
      -- Instead of true it can also be a list of languages
      additional_vim_regex_highlighting = false,
    },
  }
end

vim.cmd([[
" Required for different settings
set nocompatible

filetype plugin on
filetype indent on

" Required for coc.nvim
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
set wildmode=longest:list,full

" Show a few lines of context around the cursor.  Note that this makes the
" text scroll if you mouse-click near the start or end of the window.
set scrolloff=1

" Fix tmux scroll
set mouse=a

" Highlight search results
set hlsearch

" Show search results immediately
set incsearch

" Ignore case in search
set ignorecase
set smartcase

" Show @@@ in the last line if it is truncated.
set display=truncate

" Relative number lines on the left
set number " relativenumber

" <C-a> and <C-x> allow decrement and increment numbers
" The following setting allows to do it with characters
set nrformats+=alpha


" Notes about <leader> maps
" Note you can't use noremap with <Plug> key-mappings
" All <leader> maps are user-defined maps with the following reserved meaning:
" <leader><leader>
" <leader>%
" <leader>^
" <leader>-
" <leader>+
" <leader>*
" <leader>!
" <leader>~
" <leader><
" <leader>=
" <leader>>
" <leader>/
" <leader>(
" <leader>)
" <leader>_
" <leader>[
" <leader>]
" <leader>a
" <leader>b --- build
" <leader>c --- c, c++
" <leader>d --- debug
" <leader>e
" <leader>f
" <leader>g
" <leader>h
" <leader>i
" <leader>j
" <leader>k
" <leader>l --- coc lists
" <leader>m
" <leader>n
" <leader>o
" <leader>p --- python
" <leader>q
" <leader>r
" <leader>s --- general coc
" <leader>t --- latex
" <leader>u
" <leader>v --- vim
" <leader>w
" <leader>x
" <leader>y
" <leader>z


" Disable formatting in insert mode
" Unfortunatelly this breaks autocomplete with tab, so it is not permanently
" enabled
"set paste
" Instead use pastetoggle workaround
set pastetoggle=<C-q>
" Use <C-L> to clear the highlighting of :set hlsearch. Credit: tpope/vim-sensible
nnoremap <silent> <C-l> :nohlsearch<C-r>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-l>
" Allow refreshing screen in insert mode
inoremap <C-l> <ESC>:nohlsearch<C-r>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-l>a
" Improve C-u and C-w behaviour in insert mode
inoremap <C-u> <C-g>u<C-u>
inoremap <C-w> <C-g>u<C-w>

nnoremap <leader>vn :set invnumber<CR>
" Remove redundant spaces
nnoremap <leader>vc :%s/\([^ ]\)\s\+/\1 /g \| noh<CR>
xnoremap <leader>vc :s/\([^ ]\)\s\+/\1 /g \| noh<CR>
" Tabularize
xnoremap <leader>vt :s/\([^ ]\)\s\+/\1 /g \| noh \| '<,'>Tabularize /\s\+/l0<CR>
xnoremap <leader>vs :sort<CR>
nnoremap <leader>ve :Vexplore<CR>

" Insert spaces instead of tabs
set smarttab
set tabstop=2
set shiftwidth=2
set expandtab

set linebreak

"set foldmethod=syntax
"set foldlevel=5

set notimeout nottimeout

" Support russian with specific keyboard layouts
set keymap=rnk-russian-qwerty
set iminsert=0
set imsearch=-1
highlight lCursor guifg=NONE guibg=Cyan
inoremap <C-j> <C-^>
nnoremap <C-j> a<C-^><ESC>

" Fix CTRL-arrow behaviour
" https://unix.stackexchange.com/a/1764
map <ESC>[1;5D <C-Left>
map <ESC>[1;5C <C-Right>
map! <ESC>[1;5D <C-Left>
map! <ESC>[1;5C <C-Right>
inoremap <nowait> <ESC> <ESC>
xnoremap <nowait> <ESC> <ESC>

" Line text object
xnoremap il g_o0
onoremap il :normal vil<CR>
xnoremap al $o0
onoremap al :normal val<CR>


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
let g:netrw_preview = 1

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
silent! colorscheme onehalfdark
let g:Powerline_symbols='unicode'
let g:airline_powerline_fonts = 1
let g:airline_section_z = "%l/%L %p%%"
let g:airline_theme='onehalfdark'
set background=dark
set cursorline

" Setup vim-tmux-navigator
let g:tmux_navigator_no_mappings = 1
nnoremap <silent> <C-w>h :TmuxNavigateLeft<CR>
nnoremap <silent> <C-w>j :TmuxNavigateDown<CR>
nnoremap <silent> <C-w>k :TmuxNavigateUp<CR>
nnoremap <silent> <C-w>l :TmuxNavigateRight<CR>
nnoremap <silent> <C-w>p :TmuxNavigatePrevious<CR>
nnoremap <silent> <F2> :TmuxNavigateLeft<CR>
nnoremap <silent> <F3> :TmuxNavigateDown<CR>
nnoremap <silent> <F4> :TmuxNavigateUp<CR>
nnoremap <silent> <F5> :TmuxNavigateRight<CR>
nnoremap <silent> <F6> :TmuxNavigatePrevious<CR>

" Set up UltiSnips
let g:UltiSnipsExpandTrigger="<C-k>"
let g:UltiSnipsJumpForwardTrigger="<C-b>"
let g:UltiSnipsJumpBackwardTrigger="<C-z>"
nmap <leader>sp :UltiSnipsEdit!<CR>
xnoremap <silent> & :call UltiSnips#SaveLastVisualSelection()<CR>

nnoremap <leader>bb :build


" Setup coc.nvim
" TextEdit might fail if hidden is not set.
set hidden
" Some servers have issues with backup files,
" see https://github.com/neoclide/coc.nvim/issues/649
set nobackup
set nowritebackup
" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300
" Don't pass messages to |ins-completion-menu|.
set shortmess+=c
set signcolumn=number
" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}
" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction
function! s:coc_toggle() abort
  if g:coc_enabled
    :CocDisable
  else
    :CocEnable
  endif
endfunction
" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
" Use <c-space> to trigger completion.
inoremap <expr> <c-space> coc#refresh()

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <CR> could be remapped by other vim plugin
inoremap <expr> <CR> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap [e <Plug>(coc-diagnostic-prev)
nmap ]e <Plug>(coc-diagnostic-next)
nmap <leader>se <Plug>(coc-diagnostic-info)
" GoTo code navigation.
nmap <leader>ss <Plug>(coc-definition)
nmap <leader>st <Plug>(coc-type-definition)
nmap <leader>si <Plug>(coc-implementation)
nmap <leader>sr <Plug>(coc-references)
nmap <leader>sd :call <SID>show_documentation()<CR>
" Symbol renaming.
nmap <leader>sn <Plug>(coc-rename)
" Formatting selected code.
xmap <leader>sf <Plug>(coc-format-selected)
nmap <leader>sf <Plug>(coc-format-selected)
nmap <leader>sF <Plug>(coc-format)
" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>sa <Plug>(coc-codeaction-selected)
nmap <leader>sa <Plug>(coc-codeaction-line)
" Remap keys for applying codeAction to the current buffer.
nmap <leader>sA <Plug>(coc-codeaction)
" Apply AutoFsx to problem on the current line.
nmap <leader>sx <Plug>(coc-fix-current)
" Run the Cods Lens action on the current line.
nmap <leader>sl <Plug>(coc-codelens-action)
" Open link in browser
nmap <leader>sk <Plug>(coc-openlink)
nmap <leader>sb :abstract_syntax_tree
nmap <leader>sq :call <SID>coc_toggle()<CR>

" Free maps:
"nmap <leader>sc
"nmap <leader>sg
"nmap <leader>sh
"nmap <leader>sj
"nmap <leader>sm
"nmap <leader>so
"nmap <leader>sq
"nmap <leader>su
"nmap <leader>sv
"nmap <leader>sw
"nmap <leader>sy
"nmap <leader>sz

" Map functios and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)
" Use CTRL-S for selections ranges.  " Requires 'textDocument/selectionRange' support of language server.
nmap <C-h> <Plug>(coc-range-select)
xmap <C-h> <Plug>(coc-range-select)
" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<CR>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<CR>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif
" Mappings for CoCList
" Show commands.
nnoremap <leader>ll :<C-u>CocList lists<CR>
" Resume latest coc list.
nnoremap <leader>lr :<C-u>CocListResume<CR>
" Show commands.
nnoremap <leader>lc :<C-u>CocList commands<CR>
" Find symbol of current document.
nnoremap <leader>lo :<C-u>CocList outline<CR>
" Show all diagnostics.
nnoremap <leader>le :<C-u>CocList diagnostics<CR>
" Manage extensions.
nnoremap <leader>lx :<C-u>CocList extensions<CR>
" Search workspace symbols.
nnoremap <leader>ls :<C-u>CocList -I symbols<CR>
" Do default action for next item.
nnoremap <leader>ln :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <leader>lp :<C-u>CocPrev<CR>

augroup coc_group
  autocmd!
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Add coc extensions
let g:coc_global_extensions = []
let g:coc_global_extensions += ['coc-marketplace']

let g:coc_global_extensions += ['coc-clangd']
let g:coc_global_extensions += ['coc-cmake']
let g:coc_global_extensions += ['coc-css']
let g:coc_global_extensions += ['coc-docker']
let g:coc_global_extensions += ['coc-emoji'] "Emoji words, default enabled for markdown file only
let g:coc_global_extensions += ['coc-fish']
let g:coc_global_extensions += ['coc-html']
let g:coc_global_extensions += ['coc-json']
let g:coc_global_extensions += ['coc-lists']
let g:coc_global_extensions += ['coc-perl']
let g:coc_global_extensions += ['coc-powershell']
let g:coc_global_extensions += ['coc-python']
let g:coc_global_extensions += ['coc-sh']
let g:coc_global_extensions += ['coc-texlab']
let g:coc_global_extensions += ['coc-tsserver']
let g:coc_global_extensions += ['coc-ultisnips'] " Integration of UltiSnips to coc completion
let g:coc_global_extensions += ['coc-vimlsp']
let g:coc_global_extensions += ['coc-vimtex']
let g:coc_global_extensions += ['coc-word'] " Words from google 10000 english repo
let g:coc_global_extensions += ['coc-xml']
let g:coc_global_extensions += ['coc-yaml']

highlight RedundantSpacesAndTabs ctermbg=100 guibg=#b5942e
match RedundantSpacesAndTabs /\(\s\+$\|\t\+\)/

]])
