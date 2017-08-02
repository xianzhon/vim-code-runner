" Title:         Vim Code Runner
" Author:        Wang Xianzhong   wxz1120339073@gmail.com
"
" Goal:          Run code snippets more conveniently
"
" License:       Public domain, no restrictions whatsoever
" Documentation: type ":help CodeRunner"
"
" Version:       1.0

" Internals {{{
" Script Variables {{{
let s:CodeRunnerSourceFile=expand("<sfile>")

if !exists("g:code_runner_save_before_execute")
    let g:code_runner_save_before_execute = 0
endif
if !exists("g:code_runner_output_window_size")
    let g:code_runner_output_window_size = 15
endif

" Common {{{
" Echo {{{
function! <sid>Echo(message)
    let str = ""
    if !s:OptionsExplorerOpen
        let str .= "[CodeRunner] "
    endif
    let str .= a:message
    echo str
endfunction
"}}}
" EchoNewline {{{
function! <sid>EchoNewline()
    echo " "
endfunction
"}}}
" Quit {{{
function! <sid>Quit()
    echo ""
    quit
endfunction
" }}}
" MapOutputWindowKeys {{{
function! s:MapOutputWindowKeys()
    nnoremap <buffer> <silent> :    :call <sid>Echo("Type q to quit")<cr>
    nnoremap <buffer> <silent> q    :call <sid>Quit()<cr>
endfunction
"}}}

" }}}
" GetCommand {{{
function! s:GetCommand(type)
    let cmdMaps = s:ParseCommandAssociationList()
    if has_key(cmdMaps, a:type)
        let strCmd = cmdMaps[a:type]
    else
        return ''
    endif

    " Replace variables
    let dirPath = expand('%:h') . '/'
    let fileNameWithoutExt = expand('%:t:r')
    let fileName = expand('%:t')

    " Change to current directory if not given
    if strCmd !~ 'cd $dir'
        let strCmd = 'cd $dir && ' . strCmd
    endif
    let strCmd = substitute(strCmd, '$fileNameWithoutExt',fileNameWithoutExt,'gC')
    let strCmd = substitute(strCmd, '$fileName',fileName,'gC')
    let strCmd = substitute(strCmd, '$dir', dirPath,'gC')
    return strCmd
endfunction

" CodeRunnerCommandConfigFile {{{
function! s:GetCommandConfigFile()
    let sawError = 0
    if exists("g:code_runner_command_config_file")
        if filereadable(g:code_runner_command_config_file)
            return g:code_runner_command_config_file
        endif
        let sawError = 1
        call CodeRunner#Error("The file specified by g:code_runner_command_config_file = " .
                    \ g:code_runner_command_config_file . " cannot be read.")
        call CodeRunner#Error("Attempting to look for 'CodeRunnerCommandAssociations' in other locations.")
    endif

    let nextToSource = fnamemodify(s:CodeRunnerSourceFile, ":h")."/CodeRunnerCommandAssociations"
    if filereadable(nextToSource)
        let g:CodeRunnerCommandConfigFile = nextToSource
    else
        let VimfilesDirs = split(&runtimepath, ',')
        for v in VimfilesDirs
            let cfgFilePath = CodeRunner#BackToForwardSlash(v)."/plugin/CodeRunnerCommandAssociations"
            if filereadable(f)
                let g:CodeRunnerCommandConfigFile = cfgFilePath
            endif
        endfor
    endif

    if empty(g:CodeRunnerCommandConfigFile)
        let g:CodeRunnerCommandConfigFile = ""
    elseif sawError
        call CodeRunner#Error("    Found at: ".g:CodeRunnerCommandConfigFile)
        call CodeRunner#Error("    Please fix your configuration to suppress these messages!")
    endif
    return g:CodeRunnerCommandConfigFile
endfunction
" }}}
" ParseCommandAssociationList {{{
function! s:ParseCommandAssociationList()
    if exists("s:Dict")
        return s:Dict
    endif
    let s:Dict = {}
    if exists('g:CodeRunnerCommandMap')
        for key in keys(g:CodeRunnerCommandMap)
            let s:Dict[key] = CodeRunner#Trim(g:CodeRunnerCommandMap[key])
        endfor
    endif
    let filePath = s:GetCommandConfigFile()

    if empty(filePath)
        call CodeRunenr#Error("Code Runner Command config file not exists!")
        return
    endif

    if !filereadable(filePath)
        call CodeRunner#Error("Code Runner config file can't be read!")
        return
    endif

    let strLines = readfile(filePath)

    let lineCounter = 0
    for strLine in strLines
        let lineCounter += 1
        let strLine = CodeRunner#Trim(strLine)
        if empty(strLine) || strLine[0] == "\""
            continue
        endif

        let items = split(strLine, "::")
        if len(items) != 2
            call CodeRunner#Warning("Invalid strLine: ".strLine)
            continue
        endif

        let sourceType = CodeRunner#Trim(items[0])
        let exeCommand = CodeRunner#Trim(items[1])

        if empty(sourceType) || empty(exeCommand)
            call CodeRunner#Warning("Invalid strLine: ".strLine)
            continue
        endif
        if !has_key(s:Dict, sourceType)
            let s:Dict[sourceType] = exeCommand
        endif
    endfor
    if lineCounter == 0
        call CodeRunner#Warning("Code Runner config is empty!")
        return
    endif

    return s:Dict
endfunction
"}}}
" GotoWindowByName {{{
function! s:GotoWindowByName(bufname)
    let bufmap = map(range(1, winnr('$')), '[bufname(winbufnr(v:val)), v:val]')

    let a = filter(bufmap, 'v:val[0] =~ a:bufname')
    if len(a) > 0 && len(a[0]) > 1
        let thewindow = a[0][1]
        execute thewindow 'wincmd w'
        return 1
    endif
    return 0
endfunction
"}}}

" CodeRunner {{{
function! s:CodeRunner()
    if g:code_runner_save_before_execute == 1
        write
    endif
    let cmd = s:GetCommand(&ft)
    if empty(cmd)
        call CodeRunner#Error("Unknow File Type: " . &ft . "!")
        return
    endif
    let resList = systemlist(cmd)
    let winName = "CodeRunner.out"

    if s:GotoWindowByName(winName) == 0
        " split the window; fit exactly right
        exe "keepjumps botright ".g:code_runner_output_window_size."sp " . winName
        let isNewFile = 1
        let lnum = 0
    else
        let lnum = line('$')
        call append(lnum, '')
    end

    call s:MapOutputWindowKeys()

    setlocal bufhidden=delete
    setlocal buftype=nofile
    setlocal nobuflisted
    setlocal noswapfile
    setlocal cursorline

    call append(lnum, "[Running] " . cmd)
    for l:line in resList
      let lnum = lnum + 1
      call append(lnum, l:line)
    endfor

    " place the cursor at the end of command output
    execute lnum + 1
    " norm z.

    " Go to the source window from output window
    wincmd p
    " setlocal nomodifiable
endfunction
" }}}

if !hasmapto("<plug>CodeRunner")
    nmap <silent> <Leader>B <plug>CodeRunner
    nmap <silent> <unique> <script> <plug>CodeRunner :call <sid>CodeRunner()<CR>
endif
