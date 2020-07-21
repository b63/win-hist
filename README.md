## winhist

A plugin that keeps track of buffers opened in each window.

## Installation

To install manually clone the repository into `plugin` subdirectory of one of the runtime paths 
(`.config/nvim/plugin` or `.local/share/nvim/plugin` for NeoVim and `.vim/plugin` for Vim).

## Usage

By default, for each window 10 of the most recently opened buffers are tracked. 
To change this, modify the `g:WinHistMax` variable.
```
let g:WinHistMax = 20 " keep track of 20 most recently opened buffers
```

The default binding for switching to the previous and next buffer is `<C-P>` and `<C-N>`.
They can be changed by mapping to `<Plug>WinHistPrevBuffer` and `<Plug>WinHistNextBuffer` respectively.
```
" change mapping to <leader>n and <leader>p
noremap <silent> <leader>n <Plug>WinHistNextBuffer
noremap <silent> <leader>p <Plug>WinHistPrevBuffer
```


