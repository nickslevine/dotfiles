set nocompatible              " Use Vim defaults, not old Vi
syntax on                      " Enable syntax highlighting
filetype plugin indent on       " Detect filetypes, load plugins & smart indent
set number                      " Show line numbers
set relativenumber              " Relative line numbers for easy motion
set tabstop=4 shiftwidth=4 expandtab " 4-space soft tabs
set smartindent                 " Smarter auto-indent
set wrap                         " Soft wrap long lines
set ignorecase smartcase         " Smart case-sensitive search
set incsearch hlsearch           " Incremental search + highlight matches
set hidden                        " Allow switching buffers without saving
set undofile                      " Persistent undo across sessions
set mouse=a                       " Enable mouse support in all modes
set clipboard=unnamedplus         " Use system clipboard for all yank/paste
set ttyfast                        " Faster redrawing
set updatetime=300                 " Faster CursorHold events


nnoremap <leader>y "+y           " <leader>y to yank to system clipboard
vnoremap <leader>y "+y
nnoremap <leader>p "+p           " <leader>p to paste from system clipboard
vnoremap <leader>p "+p

" Space as <leader> key
let mapleader=" "
