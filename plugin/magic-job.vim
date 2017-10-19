function! MagicJob(qf, command)
    call s:SaveWin()
    if exists("s:mahJob") && s:mahJob != ""
        call MagicJobKill()
    endif

    if a:qf == '!'
        let s:MagicJobType = 'qf'
        call s:OpenOutBuf('qf', 1)
    else
        let s:MagicJobType = 'magic'
        call s:OpenOutBuf('magic', 1)
    endif


    let finalcmd = a:command

    let OutFn = function('s:JobPipeHandle')
    let CallbackFn = function('s:MagicCallback')
    let opts = {}
    let opts['out_io']='pipe'
    let opts['err_io']='pipe'
    let opts["out_cb"]=OutFn
    let opts["err_cb"]=OutFn
    let opts['exit_cb']=CallbackFn
    let s:mahJob = job_start([&shell, &shellcmdflag, finalcmd], opts)
    call s:StatusUpdate("[".finalcmd."]", 1)
    call s:RestoreWin()
endfunction

command! -nargs=? -bang -complete=shellcmd MagicJob call MagicJob('<bang>', <q-args>)
command! -nargs=? -bang -complete=shellcmd J call MagicJob('<bang>', <q-args>)

function! s:MagicCallback(job, status)
    call s:SaveWin()
    call s:StatusUpdate(a:status == 0 ? "[DONE]" : "[FAIL]" , a:status)
    if a:status == 0
        call s:CloseOutBufs()
    endif
    let s:mahJob=""

    call s:RestoreWin()
endfunction

function! s:StatusUpdate(msg, type)
    if a:type == 0
        let g:MagicStatusJob=''
        let g:MagicStatusWarn=''
    else
        let g:MagicStatusJob=''
        let g:MagicStatusWarn=a:msg
    endif
endfunction

function! MagicJobKill()
    if exists("s:mahJob") && s:mahJob != ""
        let g:MagicStatusWarn = "Killing Job"
        call job_stop(s:mahJob)
        let s:mahJob=""
    else
        echo "No running job"
    endif
endfunction

function! MagicJobInfo()
    if exists("s:mahJob") && s:mahJob != ""
        echo "MagicJob Status: " . job_status(s:mahJob)
    else
        echo "No running job"
    endif
endfunction

" Helper Functions
fun! s:SaveWin()
    let s:currentWin = winnr()
    let s:currentBuf = bufnr('%')
    let s:currentTab = tabpagenr()
endfun

fun! s:RestoreWin()
    if s:currentTab <= tabpagenr('$')
        silent exe "normal! ".s:currentTab."gt"
    endif
    if s:currentBuf != bufnr("MagicOutput")
        silent exe s:currentWin."wincmd w"
    endif
endfun

fun! s:OpenOutBuf(which, clear)
    if !exists('g:MagicUseEfm')
        let g:MagicUseEfm = 0
    endif

    call s:SaveWin()
    if a:which == 'qf'
        call setqflist([], 'r')
        " Not to be trusted! Specific to my usecase!
        if g:MagicUseEfm == 1
            let s:mahErrorFmt=&efm
        elseif g:MagicUseEfm == 2
            let s:mahErrorFmt=&grepformat
        endif

        silent exec 'copen'
        silent exec "wincmd J"

        " Not to be trusted! Specific to my usecase!
        if g:MagicUseEfm != 0
            exe 'set efm='.escape(s:mahErrorFmt, " ")
        endif
    else
        if bufnr("MagicOutput") == -1
            silent new MagicOutput
            wincmd J
        elseif bufwinnr("MagicOutput") != -1
            silent exe bufwinnr("MagicOutput") . "wincmd w"
        elseif bufwinnr("MagicOutput") == -1
            silent split
            silent exe "b " . bufnr("MagicOutput")
            silent exe "wincmd J"
        endif
        setlocal bufhidden=hide buftype=nofile nobuflisted nolist
        setlocal noswapfile nowrap
        set ft=log

        if a:clear | silent exe "%d" | endif

        silent resize 12
    endif
    call s:RestoreWin()

endfun
command! -nargs=0 MagicBufferOpen call s:OpenOutBuf('magic', 0)

fun! s:CloseOutBufs()
    call s:SaveWin()
    tabdo cclose
    tabdo if bufwinnr("MagicOutput")!=-1 | silent exe bufwinnr("MagicOutput")."close" | endif
    call s:RestoreWin()
endfun

fun! s:JobPipeHandle(job, message)
    if s:MagicJobType == 'qf'
        caddexpr a:message
    else

        if !exists('s:outList')
            let s:outList = []
        endif

        call add(s:outList, a:message)
        if len(s:outList) > 6
            let outBuf = bufnr("MagicOutput")
            let outWin = bufwinnr("MagicOutput")
            let saveWin = winnr()
            if outWin != -1
                if outWin == saveWin
                    silent exe outWin." wincmd w | call append(line('$'), " . string(s:outList) . ")". " | norm!G"
                else
                    silent exe outWin." wincmd w | call append(line('$'), " . string(s:outList) . ")". " | norm!G"
                    silent exe saveWin." wincmd w"
                endif
            else
                silent exe "b".outBuf." | call append(line('$'), " . string(s:outList) . ")". " | b#"
            endif
            let s:outList = []
        endif
    endif
endfun
