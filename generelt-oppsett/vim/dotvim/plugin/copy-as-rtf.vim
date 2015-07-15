" Vim plugin for copying syntax highlighted code as RTF on OS X systems
" Last Change: 2012-07-14
" Maintainer:	Nathan Witmer <nwitmer@gmail.com>
" License: WTFPL

if exists('g:loaded_copy_as_rtf')
  finish
endif
let g:loaded_copy_as_rtf = 1

" Set this to 1 to tell copy_as_rtf to use the local buffer instead of a scratch
" buffer with the selected code. Use this if the syntax highlighting isn't
" correctly handling your code when removed from its context in its original
" file.
if !exists('g:copy_as_rtf_using_local_buffer')
  let g:copy_as_rtf_using_local_buffer = 0
endif

" Set this to 1 to preserve the indentation as-is when converting to RTF.
" Otherwise, the selected lines are outdented as far as possible before
" conversion.
if !exists('g:copy_as_rtf_preserve_indent')
  let g:copy_as_rtf_preserve_indent = 0
endif

if !executable('pbcopy') || !executable('textutil')
  echomsg 'cannot load copy-as-rtf plugin, not on a mac?'
  finish
endif

" copy the current buffer or selected text as RTF
"
" bufnr - the buffer number of the current buffer
" line1 - the start line of the selection
" line2 - the ending line of the selection
function! s:CopyRTF(bufnr, line1, line2)

  " check at runtime since this plugin may not load before this one
  if !exists(':TOhtml')
    echoerr 'cannot load copy-as-rtf plugin, TOhtml command not found.'
    finish
  endif

  if g:copy_as_rtf_using_local_buffer
    let lines = getline(a:line1, a:line2)

    if !g:copy_as_rtf_preserve_indent
      call s:RemoveCommonIndentation(a:line1, a:line2)
    endif
    call tohtml#Convert2HTML(a:line1, a:line2)
    silent exe "%!textutil -convert rtf -stdin -stdout | pbcopy"

    silent bd!
    silent call setline(a:line1, lines)
  else

    " open a new scratch buffer
    let orig_ft = &ft
    new __copy_as_rtf__
    " enable the same syntax highlighting
    let &ft=orig_ft
    set buftype=nofile
    set bufhidden=hide
    setlocal noswapfile

    " copy the selection into the scratch buffer
    call setline(1, getbufline(a:bufnr, a:line1, a:line2))

    if !g:copy_as_rtf_preserve_indent
      call s:RemoveCommonIndentation(1, line('$'))
    endif

    call tohtml#Convert2HTML(1, line('$'))
    silent exe "%!textutil -convert rtf -stdin -stdout | pbcopy"
    silent bd!
    silent bd!
  endif

  echomsg "RTF copied to clipboard"
endfunction

" outdent selection to the least indented level
function! s:RemoveCommonIndentation(line1, line2)
  " normalize indentation
  silent exe a:line1 . ',' . a:line2 . 'retab'

  let lines_with_code = filter(range(a:line1, a:line2), 'match(getline(v:val), ''\S'') >= 0')
  let minimum_indent = min(map(lines_with_code, 'indent(v:val)'))
  let pattern = '^\s\{' . minimum_indent . '}'
  call setline(a:line1, map(getline(a:line1, a:line2), 'substitute(v:val, pattern, "", "")'))
endfunction

command! -range=% CopyRTF :call s:CopyRTF(bufnr('%'),<line1>,<line2>)
