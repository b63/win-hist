## winhist

A plugin that keeps track of buffers opened in each window.

## Installation

To install manually clone the repository into `plugin` subdirectory of one of the runtime paths 
(`.config/nvim/plugin` or `.local/share/nvim/plugin` for NeoVim and `.vim/plugin` for Vim).

## Usage

As buffers are opened in a window, they are tracked internally so that all buffers opened
in a window can be traversed with the `<C-P` or `<C-N>` binding (similar to switching between
tabs in a browser with CTRL+Tab and CTRL+Shift+Tab binding).

The default binding for switching to the previous and next buffer is `<C-P>` and `<C-N>`.
They can be changed by mapping to `<Plug>WinHistPrevBuffer` and `<Plug>WinHistNextBuffer` respectively.
``` vim
" change mapping to <leader>n and <leader>p
noremap <silent> <leader>n <Plug>WinHistNextBuffer
noremap <silent> <leader>p <Plug>WinHistPrevBuffer
```


