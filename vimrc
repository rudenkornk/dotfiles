" Required for different settings
set nocompatible

call plug#begin()
" The default plugin directory will be as follows:
"   - Vim (Linux/macOS): '~/.vim/plugged'
"   - Vim (Windows): '~/vimfiles/plugged'
"   - Neovim (Linux/macOS/Windows): stdpath('data') . '/plugged'
" You can specify a custom plugin directory by passing it as the argument
"   - e.g. `call plug#begin('~/.vim/plugged')`
"   - Avoid using standard Vim directory names like 'plugin'

" Make sure you use single quotes

" Use dev icons from powerline fonts
Plug 'ryanoasis/vim-devicons'

" Status line
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Colorscheme
Plug 'sonph/onehalf', { 'rtp': 'vim' }

" Underlines the word under the cursor
Plug 'itchyny/vim-cursorword'

" Surroundings: parentheses, brackets, quotes, XML tags, and more
Plug 'tpope/vim-surround'

" Unified clipboard for vim and tmux
"if v:version < 802
  Plug 'tmux-plugins/vim-tmux-focus-events'
"endif
Plug 'roxma/vim-tmux-clipboard'

" Support for .tmux.conf
Plug 'tmux-plugins/vim-tmux'

" Seemless navigation between vim and tmux
Plug 'christoomey/vim-tmux-navigator'

" Autoclose brackets
Plug 'Raimondi/delimitMate'

" Syntax highlight
Plug 'sheerun/vim-polyglot'

" Code completion
Plug 'neoclide/coc.nvim', { 'branch': 'release' }

" Initialize plugin system
call plug#end()

" vim-plug utomatically executes filetype plugin indent on and syntax enable. You can revert the settings after the call. e.g. filetype indent off, syntax off
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
set wildmode=longest:list

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

" Disable formatting in insert mode
" Unfortunatelly this breaks autocomplete with tab, so it is not permanently
" enabled
"set paste
nnoremap <leader>vp :set invpaste<cr>
nnoremap <leader>vn :set invnumber<cr>


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
set imsearch=0
highlight lCursor guifg=NONE guibg=Cyan
inoremap <C-b> <C-^>

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
onoremap il :normal vil<cr>
xnoremap al $o0
onoremap al :normal val<cr>


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
nnoremap <leader>db :Break<cr>
nnoremap <leader>dr :call TermDebugSendCommand('run')<cr>
nnoremap <leader>dn :call TermDebugSendCommand('next')<cr>
nnoremap <leader>ds :call TermDebugSendCommand('step')<cr>
nnoremap <leader>df :call TermDebugSendCommand('finish')<cr>
nnoremap <leader>dc :call TermDebugSendCommand('continue')<cr>
nnoremap <leader>du :call TermDebugSendCommand('up')<cr>
nnoremap <leader>dd :call TermDebugSendCommand('down')<cr>
nnoremap <leader>dt :call TermDebugSendCommand('backtrace')<cr>
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
nnoremap <silent> <C-w>h :TmuxNavigateLeft<cr>
nnoremap <silent> <C-w>j :TmuxNavigateDown<cr>
nnoremap <silent> <C-w>k :TmuxNavigateUp<cr>
nnoremap <silent> <C-w>l :TmuxNavigateRight<cr>
nnoremap <silent> <C-w>p :TmuxNavigatePrevious<cr>


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
" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("nvim-0.5.0") || has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif
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
" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <expr> <c-space> coc#refresh()
else
  inoremap <expr> <c-@> coc#refresh()
endif
" Make <cr> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<cr>\<c-r>=coc#on_enter()\<cr>"
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap [e <Plug>(coc-diagnostic-prev)
nmap ]e <Plug>(coc-diagnostic-next)
nmap <leader>se <Plug>(coc-diagnostic-info)
" GoTo code navigation.
nmap <leader>ss <Plug>(coc-definition)
nmap <leader>st <Plug>(coc-type-definition)
nmap <leader>si <Plug>(coc-implementation)
nmap <leader>sr <Plug>(coc-references)
nmap <leader>sd :call <SID>show_documentation()<cr>
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
augroup coc_complete
  autocmd!
  autocmd FileType cpp nnoremap <leader>ch :CocCommand clangd.switchSourceHeader<cr>
  autocmd FileType cpp nnoremap <leader>ca :CocCommand clangd.ast<cr>
  autocmd FileType cpp nnoremap <leader>cy :CocCommand clangd.symbolInfo<cr>
augroup end
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
nmap <C-q> <Plug>(coc-range-select)
xmap <C-q> <Plug>(coc-range-select)
" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif
" Mappings for CoCList
" Show commands.
nnoremap <leader>ll :<C-u>CocList lists<cr>
" Resume latest coc list.
nnoremap <leader>lr :<C-u>CocListResume<cr>
" Show commands.
nnoremap <leader>lc :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <leader>lo :<C-u>CocList outline<cr>
" Show all diagnostics.
nnoremap <leader>le :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <leader>lx :<C-u>CocList extensions<cr>
" Search workspace symbols.
nnoremap <leader>ls :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <leader>ln :<C-u>CocNext<cr>
" Do default action for previous item.
nnoremap <leader>lp :<C-u>CocPrev<cr>

augroup coc_group
  autocmd!
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Add coc extensions
let g:coc_global_extensions = []
let g:coc_global_extensions += ['coc-marketplace']

let g:coc_global_extensions += ['coc-snippets']
let g:coc_snippet_next = '<tab>'

let g:coc_global_extensions += ['coc-clangd']
let g:coc_global_extensions += ['coc-cmake']
let g:coc_global_extensions += ['coc-css']
let g:coc_global_extensions += ['coc-docker']
let g:coc_global_extensions += ['coc-html']
let g:coc_global_extensions += ['coc-json']
let g:coc_global_extensions += ['coc-perl']
let g:coc_global_extensions += ['coc-python']
let g:coc_global_extensions += ['coc-sh']
let g:coc_global_extensions += ['coc-texlab']
let g:coc_global_extensions += ['coc-tsserver']
let g:coc_global_extensions += ['coc-vimlsp']
let g:coc_global_extensions += ['coc-xml']
let g:coc_global_extensions += ['coc-yaml']

highlight RedundantSpacesAndTabs ctermbg=red guibg=red
match RedundantSpacesAndTabs /\(\s\+$\|\t\+\)/

