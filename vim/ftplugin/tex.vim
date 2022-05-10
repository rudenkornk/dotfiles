" vim's native autoformat for tex files is broken
let g:autoformat_autoindent = 0
let g:autoformat_retab = 0
let g:autoformat_remove_trailing_spaces = 0


let g:vimtex_view_general_viewer = '/mnt/c/Users/rudenkornk/AppData/Local/SumatraPDF/SumatraPDF.exe'
let g:vimtex_view_general_options = '-set-color-range #DCDFE4 #282C34 @pdf\#src:@line@tex'


" latexindent must be at least 3.8
let g:formatdef_latexindent = "'latexindent --logfile=build/latexindent.log --local --lines '.a:firstline.'-'.a:lastline.' -'"
nnoremap <leader>sF :Autoformat<CR>
xnoremap <leader>sf :Autoformat<CR>
nnoremap <leader>bb :w \| CocCommand latex.Build<CR>

