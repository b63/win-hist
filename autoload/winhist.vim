
if !exists("g:WinHistMax")
  let g:WinHistMax = 10
endif

" Contains: returns the index containing
"   `item` in `list` or return -1 if not found.
function s:Contains(item, list) " {{{1
  let n = len(a:list)
  let i = 0
  while i < n
    if a:list[l:i] == a:item
      return i
    endif
    let i += 1
  endwhile

  return -1 
endfunction "}}}1


" Remove: remove entry containing `key` from history
"   of window with winid of `winid`. The top, bot, and current
"   entry are updated to point to new entries as appropriate.
"   The current entry will point to the next entry if possible,
"   otherwise to the previous entry.
function s:Remove(key, winid) "{{{1
  let [l:top, l:cur, l:bot, l:dict] = s:winbuf_history[a:winid]
  if !has_key(l:dict, a:key)
    return [l:top, l:cur, l:bot]
  endif

  " update previous node
  let [l:prev, l:next] = l:dict[a:key]
  if l:prev != -1 && has_key(l:dict, l:prev)
    let l:dict[l:prev][1] = l:next
  endif

  " update next node
  if l:next != -1 && has_key(l:dict, l:next)
    let l:dict[l:next][0] = l:prev
  endif

  " update top
  if l:top == a:key
    let l:top = l:prev
  endif

  " update cur
  if l:cur == a:key
    if l:next == -1
      let l:cur = l:prev
    else
      let l:cur = l:next
    endif
  endif

  " update bot
  if l:bot == a:key
    let l:bot = l:next
  endif

  let s:winbuf_history[a:winid] = [l:top, l:cur, l:bot, l:dict]
  return [l:top, l:cur, l:bot]
endfunction "}}}1


" InsertAfter: insert entry for `bufn` in history dictionary
"     `dict` after the current entry. If entry with
"     key `bufn` already exists, then it is removed first.
"     The current entry will always be updated to point to newly inserted entry.
function s:InsertAfter(bufn, winid) "{{{1
  let [l:top, l:cur, l:bot, l:dict] = s:winbuf_history[a:winid]

  if has_key(l:dict, a:bufn)
    " key already exists, remove it updating top,bot,cur along the way
    let [l:top, l:cur, l:bot] = s:Remove(a:bufn, a:winid)
  endif


  if l:cur == a:bufn
    return
  elseif l:cur == -1
    " history is empty, so a:bufn will be the first item
    let l:dict[a:bufn] = [-1, -1]
    let s:winbuf_history[a:winid]  = [a:bufn, a:bufn, a:bufn, l:dict]
    return [a:bufn, a:bufn, a:bufn]
  endif

  " update next node if one exists
  let l:next = l:dict[l:cur][1]
  if l:next != -1
    let l:dict[l:next][0] = a:bufn
  endif

  " update current node
  let l:dict[l:cur][1] = a:bufn
  " insert the bufn node
  let l:dict[a:bufn]   = [l:cur, l:next]

  " update top if we inserted to top
  if l:top == l:cur
    let l:top = a:bufn
  endif

  " update global dictionary
  let s:winbuf_history[a:winid] = [l:top, a:bufn, l:bot, l:dict]
  return [l:top, a:bufn, l:bot]
endfunction "}}}1


" SeekWindowBuffer: wrapper for GetWindowBuffer to switch to the buffer
"   it returns. Same arguments as GetWindowBuffer
function winhist#SeekWindowBuffer(n) " {{{1
  let bufn = bufnr(bufname())
  let ret = s:GetWindowBuffer(a:n)
  if type(ret) == v:t_list
    let [l:seekbufn, l:n] = l:ret

    if !exists("s:winbuf_blacklist") 
      let s:winbuf_blacklist = { }
    endif

    let winid = win_getid()
    if has_key(s:winbuf_blacklist, winid)
      let blacklist = s:winbuf_blacklist[winid]
    else
      let blacklist = []
      let s:winbuf_blacklist[winid] = blacklist
    endif

    if l:bufn != l:seekbufn
      call add(blacklist, l:bufn)   " for BufWinLeave
      call add(blacklist, l:seekbufn)      " for BufWinEnter
      execute ":buffer ".l:seekbufn."\n"
    endif
  endif
endfunction " }}}1


" GetWindowBufferHistory: look n steps either backwards or forwards (+n or -n)
"   in the list of buffers opened in the current window and return the
"   buffer number. If the buffer n steps away is not laoded (:bufloaded)
"   then the last buffer that is loaded will be returned. The return value
"   is a list of two elements, the buffer number and the number of steps
"   away the returned buffer actually was. If something goes wong, then 0
"   is returned.
function s:GetWindowBuffer(n) " {{{1
  if !exists("s:winbuf_history")
    return 0
  endif

  let winid = win_getid()
  if !has_key(s:winbuf_history, winid)
    return 0
  endif

  let [l:top, l:cur, l:bot, l:hist] = s:winbuf_history[winid]
  if !has_key(l:hist, l:cur)
    return 0
  endif

  let l:seekbufn = l:cur
  let l:i = 0
  if a:n < 0
    " look backward
    while l:i > a:n && bufloaded(l:seekbufn)
      let l:temp = l:hist[l:seekbufn][0]
      if l:temp == -1
        break
      endif

      let l:seekbufn = l:temp
      let l:i -= 1
    endwhile
  else
    " look foward
    while l:i < a:n && bufloaded(l:seekbufn)
      let l:temp = l:hist[l:seekbufn][1]
      if l:temp == -1
        break
      endif

      let l:seekbufn = l:temp
      let l:i += 1
    endwhile
  endif

  if l:seekbufn == l:cur
    return [l:cur, 0]
  else
    return [l:seekbufn, l:i]
  endif
endfunction " }}}1


" PrintWindowHistory: print the dictionary value
"   for window with given winid, for debugging pruposes
function winhist#PrintWindowHistory(...) " {{{1
  if a:0 > 0
    let l:winid = a:1
  else
    let l:winid = win_getid()
  endif

  if exists("s:winbuf_history") && has_key(s:winbuf_history, l:winid)
    let [l:top, l:cur, l:bot, l:hist] = s:winbuf_history[l:winid]

    let l:arr = []
    if l:bot != -1
      let [l:c, l:duplicate] = [l:bot, 0]

      while l:c != -1 && !duplicate
        call add(l:arr, l:c)
        let l:c = l:hist[l:c][1]
        let l:duplicate = (s:Contains(l:c, l:arr) != -1)
      endwhile

      if duplicate
        echoerr "Error: circular entries in history"
      endif

      echomsg "hist: ".string(l:arr)
      echomsg "current: ".string(l:cur)
    endif
  endif

  if exists("s:winbuf_blacklist") && has_key(s:winbuf_blacklist, winid)
    echomsg "winbuf_blacklist: ".string(s:winbuf_blacklist[winid])
  endif
endfunction  " }}}1


function winhist#PrintAll() "{{{1
  if exists("s:winbuf_history")
    echomsg "winbuf_history: ".string(s:winbuf_history)
  if exists("s:winbuf_blacklist")
    echomsg "winbuf_blacklist: ".string(s:winbuf_blacklist)
  endif
endfunction "}}}1


" ClearWindowHistory: remove buffer history for a window
function winhist#ClearWindowHistory(...) " {{{1
  if a:0 > 1
    let winid = a:1
  else
    let winid = win_getid()
  endif

  if exists("s:winbuf_history") && has_key(s:winbuf_history, winid)
    unlet s:winbuf_history[winid]
    call winhist#LogWindowHistory()
  endif
endfunction " }}}1

" ClearAllWindowHistory: remove buffer history for all windows
function winhist#ClearAllWindowHistory(...) " {{{1
  if !exists("s:winbuf_history")
    return
  endif

  unlet s:winbuf_history
  let s:winbuf_history = {}
endfunction " }}}1


" RemoveWindowHistory: remove the buffer history
"   of the windows with the given winid(s).
"   If no argument is given, removes current window
function winhist#RemoveWindowHistory(...) " {{{1
  if !exists("s:winbuf_history")
    return
  endif

  if a:0 > 0
    for winid in a:000
      call remove(s:winbuf_history, winid)
    endfor
  else
    call remove(s:winbuf_history, win_getid())
  endif
endfunction " }}}1


" LogWindowBufferHistory: adds current buffer as an entry to the
"   window-local history buffers opened in the current window.
function winhist#LogWindowHistory() " {{{1
  if !exists("s:winbuf_history")
    let s:winbuf_history = {}
  endif

  let winid = win_getid()

  if has_key(s:winbuf_history, l:winid)
    " top: top/head of linked list
    " bot: bottom/tail of linked list
    " cur: current entry in linked list; new buffers(nodes) inserted
    "      after this entry
    " an 'entry' or 'node' refers to an item the history(dictionary)
    " the keys are the buffer ids and value is [prev, next] where
    " prev is the buffer-id of the previous buffer/node the next is
    " the next buffer/node in the linked list
    let [l:top, l:cur, l:bot, l:hist] = s:winbuf_history[l:winid]
  else
    let [l:top, l:cur, l:bot, l:hist] = [-1, -1, -1, {}]
    let s:winbuf_history[winid] = [-1, -1, -1, l:hist]
  endif

  let bufn = bufnr(bufname())
  if exists("s:winbuf_blacklist") && has_key(s:winbuf_blacklist, winid)
    let blacklist = s:winbuf_blacklist[winid]
    let i = s:Contains(bufn, blacklist)

    if l:i != -1
      call remove(blacklist, l:i)
      let s:winbuf_history[winid][1] = l:bufn
      return
    endif
  endif

  call s:InsertAfter(l:bufn, l:winid)
endfunction " }}}1


