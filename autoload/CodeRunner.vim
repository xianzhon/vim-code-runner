" Ouput Message {{{
function! CodeRunner#Error(message)
    echohl ErrorMsg | echomsg "[CodeRunner] Error: ".a:message | echohl None
endfunction
function! CodeRunner#Warning(message)
    echohl WarningMsg | echomsg "[CodeRunner] Warning: ".a:message | echohl None
endfunction
"}}}
" Trim {{{
function! CodeRunner#Trim(s)
    let len = strlen(a:s)

    let beg = 0
    while beg < len
        if a:s[beg] != " " && a:s[beg] != "\t"
            break
        endif
        let beg += 1
    endwhile

    let end = len - 1
    while end > beg
        if a:s[end] != " " && a:s[end] != "\t"
            break
        endif
        let end -= 1
    endwhile

    return strpart(a:s, beg, end-beg+1)
endfunction
"}}}
" BackToForwardSlash {{{
function! CodeRunner#BackToForwardSlash(arg)
    return substitute(a:arg, '\\', '/', 'g')
endfunction
"}}}
