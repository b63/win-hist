
if !exists("g:WinHistMax")
  let g:WinHistMax = 10
endif

let s:MaxStackSize = g:WinHistMax + 1

" WrapInt: 'wrap' an integer between 0 and a bound
function s:WrapInt(max_exclusive, value) " {{{1
  let modv = abs(a:value) % a:max_exclusive

  if a:value < 0 && modv != 0
    return a:max_exclusive - modv
  endif
  return modv
endfunction " }}}1

" PushCyclicList: push repeating items in list to a 'cyclic' stack
"   duplicate consequtive items are not added
function s:PushCyclicList(top, size, stack, items) " {{{1
  let max_size = len(a:stack)
  let top = a:top
  let length = len(a:items)
  let dupcliate = 0

  if length < 1
    return
  endif

  let i = 0
  if a:size > 0
    let prev = a:stack[s:WrapInt(max_size, l:top - 1)]
  else
    let prev = a:items[0]
    let a:stack[l:top] = l:prev
    let l:top = (l:top + 1) % max_size
    let l:i += 1
  endif

  while i < length
    " note: bad if max_size << len(a:items)
    if prev != a:items[l:i]
      let a:stack[l:top] = a:items[l:i]
      let l:top = (l:top + 1) % max_size
    else
      let dupcliate += 1
    endif

    let l:i += 1
  endwhile

  return [l:top, min(a:size + length - dupcliate, max_size)]
endfunction " }}}1

" PushCyclic: push items in list to a 'cyclic' stack
"   if the last item on the stack is the same, then
"   the new item is not pushed
function s:PushCyclic(top, size, stack, item) " {{{1
  let max_size = len(a:stack)
  if a:size > 0
    let prev = a:stack[s:WrapInt(max_size, a:top - 1)] 
    if prev == a:item
      return [a:top, a:size]
    endif
  endif

  let a:stack[a:top] = a:item

  return [(a:top + 1) % max_size, min([a:size + 1, max_size])]
endfunction " }}}1

" SeekWindowBuffer: wrapper for GetWindowBuffer to switch to the buffer
"   it returns. Same arguments as GetWindowBuffer
function winhist#SeekWindowBuffer(n) " {{{1
  let ret = s:GetWindowBuffer(a:n)
  if type(ret) == v:t_list && len(ret) == 2
    let [l:bufn, l:n] = l:ret

    if !exists("s:winbuf_blacklist") 
      let s:winbuf_blacklist = { }
    endif
    
    let win_id = win_getid()
    if has_key(s:winbuf_blacklist, win_id)
      let blacklist = s:winbuf_blacklist[win_id]
    else
      let blacklist = []
      let s:winbuf_blacklist[win_id] = []
    endif

    call add(blacklist, bufn)
    execute ":buffer ".bufn."\n"
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
    return
  endif

  let winid = win_getid()
  if !has_key(s:winbuf_history, winid)
    return 0
  endif

  let [l:top, l:ptop, l:size, l:stack] = s:winbuf_history[winid]
  if l:size < 1
    return 0
  endif
  let max_size = len(l:stack)
  if l:top >= l:ptop
    let diff = l:top - l:ptop
  else
    let diff = l:top + (max_size - l:ptop)
  endif

  if a:n < 0
    let l:n = max([-l:size + diff + 1, a:n])
    let i = 0
    while i >= l:n
      let bufn = l:stack[s:WrapInt(max_size, l:ptop + l:i - 1)]
      if bufloaded(bufn)
        let seekbufn = bufn
        let l:newptop = s:WrapInt(max_size, l:ptop + l:i)
      endif
      let l:i -= 1
    endwhile
  elseif a:n > 0
    let l:n = min([diff, a:n])
    let i = 0
    while i <= l:n
      let bufn = l:stack[s:WrapInt(max_size, l:ptop + l:i - 1)]
      if bufloaded(bufn)
        let seekbufn = bufn
        let l:newptop = s:WrapInt(max_size, l:ptop + l:i)
      endif
      let l:i += 1
    endwhile
  else
    let seekbufn = l:stack[s:WrapInt(max_size, l:ptop-1)]
    let l:newptop = l:ptop
    let l:n = 0
  endif

  if exists("l:newptop") && exists("l:seekbufn")
    let s:winbuf_history[winid][1] = l:newptop
    return [seekbufn, l:n]
  else
    return 0
  endif
endfunction " }}}1

" LogWindowBufferHistory: adds current buffer as an entry to the
"   window-local history buffers opened in the current window
function winhist#LogWindowHistory(...) " {{{1
  if !exists("s:winbuf_history")
    let s:winbuf_history = {}
  endif

  let winid = win_getid()

  if has_key(s:winbuf_history, winid)
    let [l:top, l:ptop, l:size, l:stack] = s:winbuf_history[winid]
  else
    let [l:top, l:ptop, l:size, l:stack] = [0, 0, 0, []]
    let i = 0

    " fill array
    while i < s:MaxStackSize
      call add(l:stack, -1)
      let i += 1
    endwhile

    let s:winbuf_history[winid] = [0, 0, 0, l:stack]
  endif

  if a:0 > 0
    let [newtop, newsize] = s:PushCyclicList(l:ptop, l:size, l:stack, a:000)
  else
    let bufn = bufnr(bufname())
    if exists("s:winbuf_blacklist") && has_key(s:winbuf_blacklist, winid)
      let [blacklist, blacklisted, l:i] = [s:winbuf_blacklist[winid], 0, 0]
      while l:i < len(blacklist)
        if blacklist[l:i] == bufn
          let blacklisted = 1
          call remove(blacklist, l:i)
          break
        endif
        let l:i += 1
      endwhile

      " don't push onto history if blacklisted
      if blacklisted
        return
      endif
    endif

    let [newtop, newsize] = s:PushCyclic(l:ptop, l:size, l:stack, bufnr(bufname()))
  endif

  let s:winbuf_history[winid][0] = l:newtop
  let s:winbuf_history[winid][1] = l:newtop
  let s:winbuf_history[winid][2] = l:newsize
endfunction " }}}1


