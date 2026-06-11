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
    let g:code_runner_save_before_execute = 1
endif
if !exists("g:code_runner_output_window_size")
    let g:code_runner_output_window_size = 15
endif
if !exists("g:code_runner_reuse_output_window")
    let g:code_runner_reuse_output_window = 1
endif
if !exists("g:code_runner_focus_output_window")
    let g:code_runner_focus_output_window = 0
endif

let s:term_bufnr = -1

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
    nnoremap <buffer> <silent> q    :call <sid>Quit()<cr>
endfunction
" }}}
" GetSafePath {{{
function! s:GetSafePath(path)
    " Wrap the path with double quotes if it contains space
    if stridx(a:path, ' ') == -1
        return a:path
    endif
    return '"' . a:path . '"'
endfunction
" }}}
" }}} - End of Common

" GetCommand {{{

function! s:GetCommand(type)abort
    let cmdMaps = s:ParseCommandAssociationList()
    if has_key(cmdMaps, a:type)
        let strCmd = cmdMaps[a:type]
    else
        return ''
    endif

    " Replace path variables
    let dirPath = s:GetSafePath(expand('%:h') . '/')
    let fileNameWithoutExt = s:GetSafePath(expand('%:t:r'))
    let fileName = s:GetSafePath(expand('%:t'))

    " Change to current directory if not given
    if strCmd !~ 'cd $dir'
        let strCmd = 'cd $dir && ' . strCmd
    endif

    let strCmd = substitute(strCmd, '$fileNameWithoutExt', fileNameWithoutExt, 'gC')
    let strCmd = substitute(strCmd, '$fileName', fileName, 'gC')
    let strCmd = substitute(strCmd, '$dir', dirPath, 'gC')

    return strCmd
endfunction
" }}}

" GetCommandConfigFile {{{
function! s:GetCommandConfigFile()
    " Check for .coderunner in current file's directory
    let currentDir = expand('%:p:h')
    let currentConfig = currentDir . '/.coderunner'
    if filereadable(currentConfig)
        return currentConfig
    endif

    " Check for .coderunner in project root (git repo)
    let projectRoot = finddir('.git', currentDir . ';')
    if !empty(projectRoot)
        let projectRoot = fnamemodify(projectRoot, ':h')
        let projectConfig = projectRoot . '/.coderunner'
        if filereadable(projectConfig)
            return projectConfig
        endif
    endif

    " Fall back to global config
    if exists("g:code_runner_command_config_file")
        if filereadable(g:code_runner_command_config_file)
            return g:code_runner_command_config_file
        endif
        call CodeRunner#Error("The file specified by g:code_runner_command_config_file = " .
                    \ g:code_runner_command_config_file . " cannot be read.")
    endif

    let nextToSource = fnamemodify(s:CodeRunnerSourceFile, ":h")."/CodeRunnerCommandAssociations"
    if filereadable(nextToSource)
        let l:CodeRunnerCommandConfigFile = nextToSource
    else
        let VimfilesDirs = split(&runtimepath, ',')
        for v in VimfilesDirs
            let cfgFilePath = CodeRunner#BackToForwardSlash(v)."/plugin/CodeRunnerCommandAssociations"
            if filereadable(cfgFilePath)
                let l:CodeRunnerCommandConfigFile = cfgFilePath
            endif
        endfor
    endif

    if empty(l:CodeRunnerCommandConfigFile)
        let l:CodeRunnerCommandConfigFile = ""
    elseif sawError
        call CodeRunner#Error("    Found at: ".l:CodeRunnerCommandConfigFile)
        call CodeRunner#Error("    Please fix your configuration to suppress these messages!")
    endif
    return l:CodeRunnerCommandConfigFile
endfunction
" }}}
" ParseCommandAssociationList {{{
function! s:ParseCommandAssociationList()
    if exists("s:Dict")
        return s:Dict
    endif
    let s:Dict = {}
    if exists('g:code_runner_command_map')
        for key in keys(g:code_runner_command_map)
            let s:Dict[key] = CodeRunner#Trim(g:code_runner_command_map[key])
        endfor
    endif
    let filePath = s:GetCommandConfigFile()

    if empty(filePath)
        call CodeRunner#Error("Code Runner Command config file not exists!")
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
" GotoOutputWindow {{{
function! s:GotoOutputWindow()
    for i in range(1, winnr('$'))
        let bname = bufname(winbufnr(i))
        if bname =~# 'CodeRunner.out' || getbufvar(winbufnr(i), '&buftype') ==# 'terminal'
            execute i . 'wincmd w'
            return 1
        endif
    endfor
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

    let srcwinnr = winnr()
    if g:code_runner_reuse_output_window && s:GotoOutputWindow()
        if has('nvim')
            execute 'terminal ' . cmd
        else
            close!
            execute "belowright terminal ++shell ++rows=" . g:code_runner_output_window_size . " " . cmd
        endif
        call s:MapOutputWindowKeys()
        if !g:code_runner_focus_output_window
            execute srcwinnr . 'wincmd w'
        endif
        return
    endif

    let winName = "CodeRunner.out"
    if has('nvim')
        exec "belowright ".g:code_runner_output_window_size."sp ".winName." | terminal ".cmd
    else
        exec "belowright terminal ++shell ++rows=".g:code_runner_output_window_size." ".cmd
    endif
    let s:term_bufnr = bufnr('%')

    call s:MapOutputWindowKeys()

    if !g:code_runner_focus_output_window
        execute srcwinnr . 'wincmd w'
    endif
endfunction
" }}}

nnoremap <silent> <plug>CodeRunner :call <sid>CodeRunner()<CR>
if !hasmapto("<plug>CodeRunner")
    nmap <silent> <Leader>B <plug>CodeRunner
endif
