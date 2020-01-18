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

colorscheme molokai

call plug#begin('~/.config/nvim/plugged')

Plug 'pangloss/vim-javascript'
Plug 'crusoexia/vim-javascript-lib'
Plug 'isruslan/vim-es6'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'vim-scripts/scrollfix'
Plug 'Raimondi/delimitMate'
Plug 'tpope/vim-surround'
Plug 'wincent/command-t'
call plug#end()

let g:go_highlight_build_constraints = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_highlight_structs = 1
let g:go_highlight_method_calls = 1



let g:scrollfix=65

let g:go_def_mode='gopls'
let g:go_info_mode='gopls'

noremap <C-t> :CommandT<Enter>
inoremap <C-t> <Esc>:CommandT<Enter>
noremap <C-s> :w<Enter>
inoremap <C-s> <Esc>:w<Enter>
noremap <C-h> b
noremap <C-l> w
noremap <C-z> :u<Enter>
inoremap <C-z> <Esc>:u<Enter>i
noremap <C-y> :redo<Enter>
inoremap <C-y> <Esc>:redo<Enter>i
noremap <C-j> :$<Enter>
noremap <C-k> gg
noremap <C-c> y
noremap <C-x> d
noremap <C-v> p
noremap <C-p> <C-v>
inoremap <C-o> <Esc>o

" vim-go settings
let g:go_fmt_command = "goimports"

map <C-n> :cnext<CR>           " jump to next issue in error window
map <C-m> :cprevious<CR>       " jump to previous issue in error window
nnoremap <leader>a :cclose<CR> " close quickfix window

autocmd FileType go nmap <leader>r <Plug>(go-run)             " run package
autocmd FileType go nmap <leader>t <Plug>(go-test)            " run go tests
autocmd FileType go nmap <leader>c <Plug>(go-coverage-toggle) " toggle go coverage syntax highlighting

" run build or test/compile depending on file contents
function! s:build_go_files()
    let l:file = expand('%')
    if l:file =~# '^\f\+_test\.go$'
        call go#test#Test(0, 1)
    elseif l:file =~# '^\f\+\.go$'
        cal go#cmd#Build(0)
    endif
endfunction

autocmd FileType go nmap <leader>b :<C-u>call <SID>build_go_files()<CR>

" Build / Test on save
augroup auto_go
    autocmd!
    autocmd BufWritePost *.go :GoBuild!
    autocmd BufWritePost *.go :GoTest
augroup end

" coc.nvim config
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" use right arrow for to confirm completion
inoremap <silent><expr> <C-Right> coc#refresh()

" settings for splits
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" netrw settings
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 0 
let g:netrw_winsize = 15

let g:NetrwIsOpen=0

function! ToggleNetrw()
    if g:NetrwIsOpen
        let i = bufnr("$")
        while (i >= 1)
            if (getbufvar(i, "&filetype") == "netrw")
                silent exe "bwipeout " . i 
            endif
            let i-=1
        endwhile
        let g:NetrwIsOpen=0
    else
        let g:NetrwIsOpen=1
        silent Lexplore
    endif
endfunction

noremap <leader>n :call ToggleNetrw()<CR>
