set nocompatible            " disable compatibility to old-time vi
set number
set showmatch               " show matching brackets.
set ignorecase              " case insensitive matching
set mouse=v                 " middle-click paste with mouse
set hlsearch                " highlight search results
set tabstop=4               " number of columns occupied by a tab character
set softtabstop=4           " see multiple spaces as tabstops so <BS> does the right thing
set expandtab               " converts tabs to white space
set shiftwidth=4            " width for autoindents
set autoindent              " indent a new line the same amount as the line just typed
set number                  " add line numbers
set wildmode=longest,list   " get bash-like tab completions
set cc=80                   " set an 80 column border for good coding style
filetype plugin indent on   " allows auto-indenting depending on file type
set termguicolors           " allow true colors in terminal
syntax on                   " syntax highlightinget nocompatible 

colorscheme monokai

call plug#begin('~/.config/nvim/plugged')

Plug 'pangloss/vim-javascript'
Plug 'crusoexia/vim-javascript-lib'
Plug 'isruslan/vim-es6'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'vim-scripts/scrollfix'
Plug 'Raimondi/delimitMate'

call plug#end()

let g:go_highlight_build_constraints = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_highlight_structs = 1
let g:go_auto_sameids = 1
let g:go_highlight_method_calls = 1



let g:scrollfix=65

let g:go_def_mode='gopls'
let g:go_info_mode='gopls'

"So I can move around in insert
inoremap <C-k> <C-o>k
inoremap <C-h> <Left>
inoremap <C-l> <Right>
inoremap <C-j> <C-o>j

let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 2
let g:netrw_winsize = 15

noremap <C-s> :w<Enter>
inoremap <C-s> <Esc>:w<Enter>
" noremap <C-S> :wq<Enter>
" inoremap <C-S> <Esc>:wq<Enter>
noremap <C-h> b
noremap <C-l> w
noremap <C-z> :u<Enter>
inoremap <C-z> <Esc>:u<Enter>i
noremap <C-y> :redo<Enter>
inoremap <C-y> <Esc>:redo<Enter>i
