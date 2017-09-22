" Functions to be used as operator pending mappings

" Stamp last yank over motion/selection
function! MagicStamp(type, ...)
    call MagicDo(a:type, "\"0p", a:000)
endfunction

" yank motion/selection to system clipboard
function! MagicClip(type, ...)
    call MagicDo(a:type, "\"*y", a:000)
endfunction

" Stamp system clipboard over motion/selection
function! MagicPaste(type, ...)
    call MagicDo(a:type, "\"*p", a:000)
endfunction

" Stamp system clipboard over motion/selection
function! MagicCalc(type, ...)
    call MagicDo(a:type, "c\<c-r>=\<c-r>\"\<cr>", a:000)
endfunction

" Helper function
function! MagicDo(type, what_magic, ...)
    let sel_save = &selection
    let &selection = "inclusive"
    let reg_save = @@

    if a:type == 'v'  " Invoked from Visual mode, use gv command.
        silent exe "normal! gv" . a:what_magic
    elseif a:type == 'line'
        silent exe "normal! '[V']" . a:what_magic
    else
        silent exe "normal! `[v`]" . a:what_magic
    endif

    let &selection = sel_save
    let @@ = reg_save
endfunction

nnoremap <Plug>MagicStamp :set opfunc=MagicStamp<CR>g@
vnoremap <Plug>MagicStamp :<C-U>call MagicStamp(visualmode())<CR>

nnoremap <Plug>MagicClip :set opfunc=MagicClip<CR>g@
vnoremap <Plug>MagicClip :<C-U>call MagicClip(visualmode())<CR>

nnoremap <Plug>MagicPaste :set opfunc=MagicPaste<CR>g@
vnoremap <Plug>MagicPaste :<C-U>call MagicPaste(visualmode())<CR>

nnoremap <Plug>MagicCalc :set opfunc=MagicCalc<CR>g@
vnoremap <Plug>MagicCalc :<C-U>call MagicCalc(visualmode())<CR>
