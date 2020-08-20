
if exists("g:loaded_winhist")
  finish
endif
let g:loaded_winhist = 1

augroup WindowHistory
  au!
  au WinNew      * call winhist#LogWindowHistory()
  au BufWinEnter * call winhist#LogWindowHistory()
  au BufWinLeave * call winhist#LogWindowHistory()
augroup END

if !hasmapto("<Plug>WinHistNextBuffer")
  silent! map <unique> <C-N> <Plug>WinHistNextBuffer
endif
noremap <unique> <silent> <script> <Plug>WinHistNextBuffer :call winhist#SeekWindowBuffer(1)<cr>

if !hasmapto("<Plug>WinHistPrevBuffer")
  silent! map <unique> <C-P> <Plug>WinHistPrevBuffer
endif
noremap <unique> <silent> <script> <Plug>WinHistPrevBuffer :call winhist#SeekWindowBuffer(-1)<cr>
