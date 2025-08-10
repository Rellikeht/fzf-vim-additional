" helpers {{{ 

function s:backup_status()
  let b:fzf_add_status_bck = [&laststatus, &showmode, &ruler]
endfunction

function s:restore_status()
  exe "set laststatus=".b:fzf_add_status_bck[0]
  exe "set showmode=".b:fzf_add_status_bck[1]
  exe "set ruler=".b:fzf_add_status_bck[2]
endfunction

function! s:with_dir(dir='')
  if len(a:dir) == 0
    return {}
  endif
  if type(a:dir) == v:t_list
    let l:dir = a:dir[0]
  else
    let l:dir = a:dir
  endif
  return {'dir': l:dir}
endfunction

function! s:W0(...)
  return join(a:000[1:], '')
endfunction

" An action can be a reference to a function that processes selected lines
function! s:build_quickfix_list(lines, action = 'r')
  let lns = map(deepcopy(a:lines),
        \ '{ "filename": v:val'.
        \ ', "lnum": 1'.
        \ ' }'
        \ )
  if g:qfloc
    call setloclist(0, lns)
  else
    call setqflist(lns)
  endif
  call QFcmd('open')
endfunction

func s:fnameescape(key, val)
  return fnameescape(a:val)
endfunc

function! s:populate_arg_list(lines)
  execute 'args ' . join(map(a:lines, function('s:fnameescape')), ' ')
endfunction

function! s:add_arg_list(lines)
  execute 'argadd ' . join(map(a:lines, function('s:fnameescape')), ' ')
endfunction

function! s:tab_args(lines)
  Tabe
  execute 'args ' . join(map(a:lines, function('s:fnameescape')), ' ')
endfunction

" }}} 

" settings {{{ 

if !exists("g:fzf_add_hide_statusline")
  let g:fzf_add_hide_statusline = 1
endif

if g:fzf_add_hide_statusline
  " Slightly more sophisticated version of
  " https://github.com/junegunn/fzf.vim/blob/master/README.md#status-line-of-terminal-buffer
  autocmd! FileType fzf call <SID>backup_status()
        \| set laststatus=0 noshowmode noruler
        \| autocmd BufLeave <buffer> call <SID>restore_status()
endif

" }}} 

" grep {{{ 

let s:ggrep_args = '--line-number --color=always -EI'
let s:grep = g:grep_prog.' -r '.s:ggrep_args
" let s:ggrep_args = s:ggrep_args.' -EI'

" simple grep
command! -bang -nargs=* Fgrep
      \ call fzf#vim#grep(
      \ s:grep." -- ".fzf#shellescape(<q-args>),
      \ fzf#vim#with_preview(),
      \ <bang>0
      \ )

" grep on given directory
command! -bang -nargs=* -complete=dir Dgrep
      \ call fzf#vim#grep(
      \ s:grep." -- ".fzf#shellescape(s:W0(<f-args>)),
      \ extend(
      \ fzf#vim#with_preview(),
      \ s:with_dir([<f-args>]),
      \ ),
      \ <bang>0
      \ )

" case insensitive grep on given directory
command! -bang -nargs=* -complete=dir Digrep
      \ call fzf#vim#grep(
      \ s:grep." -i -- ".fzf#shellescape(s:W0(<f-args>)),
      \ extend(
      \ fzf#vim#with_preview(),
      \ s:with_dir([<f-args>]),
      \ ),
      \ <bang>0
      \ )

" }}} 

" ag {{{ 

let s:ahflags = '--ignore .git --ignore .hg --smart-case --hidden'
let s:auflags = '--ignore .git --ignore .hg --smart-case --unrestricted'

command! -bang -nargs=* Ah 
      \ call fzf#vim#ag(<q-args>,
      \ s:ahflags,
      \ fzf#vim#with_preview(),
      \ <bang>0)

command! -bang -nargs=* Au 
      \ call fzf#vim#ag(<q-args>,
      \ s:auflags,
      \ fzf#vim#with_preview(),
      \ <bang>0)

" Ag from given directory
command! -bang -nargs=* -complete=dir Dah
      \ call fzf#vim#ag(s:W0(<f-args>),
      \ s:ahflags,
      \ extend(
      \ s:with_dir([<f-args>]),
      \ extend(deepcopy(g:fzf_layout), fzf#vim#with_preview())
      \ ), <bang>0)

command! -bang -nargs=* -complete=dir Dau
      \ call fzf#vim#ag(s:W0(<f-args>),
      \ s:auflags,
      \ extend(
      \ s:with_dir([<f-args>]),
      \ extend(deepcopy(g:fzf_layout), fzf#vim#with_preview())
      \ ), <bang>0)

" }}} 

" rg {{{ 

let s:rgcmd = "rg --column --line-number --no-heading --hidden ".
      \ "--color=always --smart-case "
command! -bang -nargs=* -complete=dir Drg
      \ call fzf#vim#grep(
      \ s:rgcmd.' --glob="!.git" --glob="!.hg" -- '.
      \ fzf#shellescape(s:W0(<f-args>)),
      \ extend(
      \ s:with_dir(<f-args>),
      \ extend(deepcopy(g:fzf_layout), fzf#vim#with_preview())
      \ ), <bang>0)

command! -bang -nargs=* -complete=dir Dru
      \ call fzf#vim#grep(
      \ s:rgcmd.' --unrestricted -- '.fzf#shellescape(s:W0(<f-args>)),
      \ extend(
      \ s:with_dir(<f-args>),
      \ extend(deepcopy(g:fzf_layout), fzf#vim#with_preview())
      \ ), <bang>0)

" }}} 

" diff {{{ 

" TODO C preview like in other commands (probably impossible)
command! -bang -nargs=? -complete=dir Fdiffs
      \ call fzf#run(fzf#wrap({
      \ 'sink': 'diffs',
      \ 'dir': <q-args>,
      \ 'options': [
      \ '--preview',
      \ 'delta '.Expand("%:p").' {}',
      \ '--preview-window',
      \ g:fzf_preview_default,
      \ ],
      \ },
      \ <bang>0))

command! -bang -nargs=? -complete=dir Fdiffv
      \ call fzf#run(fzf#wrap({
      \ 'sink': 'vert diffs',
      \ 'dir': <q-args>,
      \ 'options': [
      \ '--preview',
      \ 'delta '.Expand("%:p").' {}',
      \ '--preview-window',
      \ g:fzf_preview_default,
      \ ],
      \ },
      \ <bang>0)
      \ )

" }}} 

" other {{{

" From official instructions
" git grep
command! -bang -nargs=* GGrep
      \ call fzf#vim#grep(
      \   'git grep '.s:ggrep_args.' -r -- '.fzf#shellescape(<q-args>),
      \   fzf#vim#with_preview(
      \      {'dir': GitRoot()}
      \   ), <bang>0)

" }}}
