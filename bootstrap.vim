scriptencoding utf-8

let s:IS_WIN = has('win16') || has('win32')
\               || has('win64') || has('win95')
let s:IS_MAC = !s:IS_WIN && !has('win32unix') && (has('mac') || has('macunix') || has('gui_macvim') || (!executable('xdg-open') && system('uname') =~? '^darwin'))
let s:PATH_SEP = s:IS_WIN ? '\' : '/'
let s:VOLT_CMD_VERSION = 'v0.0.0-alpha'

function! s:download() abort
  let goos = s:goos()
  let goarch = s:goarch()
  if goos is '' || goarch is ''
    echoerr printf('Cannot detect your environment''s GOOS or GOARCH: GOOS=%s, GOARCH=%s', goos, goarch)
    return 100
  endif
  let is_win = goos is 'windows'
  let ext = is_win ? '.exe' : ''
  let url = printf('https://github.com/vim-volt/go-volt/releases/download/%s/volt-%s-%s-%s%s', s:VOLT_CMD_VERSION, s:VOLT_CMD_VERSION, goos, goarch, ext)
  let volt_cmd = s:Path.volt_cmd()
  silent! call mkdir(fnamemodify(volt_cmd, ':h'), 'p')
  if !isdirectory(fnamemodify(volt_cmd, ':h'))
    echohl ErrorMsg
    echomsg 'Could not create directory: ' . volt_cmd
    echohl None
    return 101
  endif
  return s:fetch_to(url, volt_cmd)
endfunction

function! s:fetch_to(url, volt_cmd) abort
  echomsg 'Downloading' a:url '...'
  if executable('curl') && executable('chmod')
    call system('curl -Lo ' . s:Path.shellescape(a:volt_cmd) . ' ' . a:url)
    call system('chmod +x ' . s:Path.shellescape(a:volt_cmd))
    return system(a:volt_cmd . ' version') =~# 'volt ' . s:VOLT_CMD_VERSION ? 0 : 102
  else
    " TODO: Support more commands
    echohl ErrorMsg
    echomsg 'Cannot download volt binary'
    echomsg 'Please install ''curl'' command'
    echohl None
    return 103
  endif
endfunction

function! s:goos() abort
  if s:IS_WIN
    return 'windows'
  elseif s:IS_MAC
    return 'darwin'
  else
    return 'linux'
  endif
endfunction

function! s:goarch() abort
  if !s:IS_WIN
    return 'amd64'    " TODO: detect
  endif
  return $ProgramW6432 isnot '' ? 'amd64' : '386'
endfunction

let s:Path = {}

function! s:Path.volt_path() abort
  if $VOLT_PATH isnot ''
    return $VOLT_PATH
  endif
  let home = $HOME
  if home is ''
    let home = $APPDATA
    if home is ''
      throw 'Couldn''t look up VOLTPATH'
    endif
  endif
  return s:Path.join(home, 'volt')
endfunction

function! s:Path.join(...) abort
  return join(a:000, s:PATH_SEP)
endfunction

function! s:Path.volt_cmd() abort
  return s:Path.join(s:Path.volt_path(), 'bin', 'volt')
endfunction

function! s:Path.shellescape(path) abort
  let old = &l:shellslash
  let &l:shellslash = 0
  try
    return call('shellescape', [a:path])
  finally
    let &l:shellslash = old
  endtry
endfunction

function! s:show_guide() abort
  tabedit
  call setline(1, [
  \ '',
  \ "`8.`888b           ,8'  ,o888888o.     8 8888   8888888 8888888888",
  \ " `8.`888b         ,8'. 8888     `88.   8 8888         8 8888",
  \ "  `8.`888b       ,8',8 8888       `8b  8 8888         8 8888",
  \ "   `8.`888b     ,8' 88 8888        `8b 8 8888         8 8888",
  \ "    `8.`888b   ,8'  88 8888         88 8 8888         8 8888",
  \ "     `8.`888b ,8'   88 8888         88 8 8888         8 8888",
  \ "      `8.`888b8'    88 8888        ,8P 8 8888         8 8888",
  \ "       `8.`888'     `8 8888       ,8P  8 8888         8 8888",
  \ "        `8.`8'       ` 8888     ,88'   8 8888         8 8888",
  \ "         `8.`           `8888888P'     8 888888888888 8 8888",
  \ "",
  \ "Hello! this is introduction guide to set up volt",
  \])
endfunction

" Download volt binary from GitHub
let s:code = s:download()
if s:code > 0
  throw 'Failed to download volt binary (' . s:code . ')'
endif

if $VOLT_NOGUIDE is ''
  " Show installation guide for user
  call s:show_guide()
endif
