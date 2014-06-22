"" Based on tips from  VIM Revisited (after dropping Janus)
"" http://mislav.uniqpath.com/2011/12/vim-revisited/

set nocompatible                " choose no compatibility with legacy vi
syntax enable
set encoding=utf-8
filetype plugin indent on       " load file type plugins + indentation

"" GUI
colorscheme darkblue
set guifont=Monaco:h14

"" check out http://superuser.com/questions/693528/vim-is-there-a-downside-to-using-space-as-your-leader-key
:let mapleader="," 
set showcmd "" show leader commands

"" Whitespace
set nowrap                      " don't wrap lines
set tabstop=4 shiftwidth=4      " a tab is four spaces 
set expandtab                   " use spaces, not tabs (optional)
set backspace=indent,eol,start  " backspace through everything in insert mode

"" Searching
set hlsearch                    " highlight matches
set incsearch                   " incremental searching
set ignorecase                  " searches are case insensitive...
set smartcase                   " ... unless they contain at least one capital letter

set printoptions=portrait:n


"" File type settings
" associate *.vss (VectorScript) with Pascal filetype
au BufRead,BufNewFile *.vss set filetype=pascal
" associate Processing files with Java
au BufRead,BufNewFile *.pde set filetype=java

autocmd Filetype text setlocal wrap

source ~/.vimrc.local
