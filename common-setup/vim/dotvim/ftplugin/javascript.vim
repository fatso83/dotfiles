" It's not CoC, AutoCmd BufWritePre, Neoformat that invokes Prettier, it's ALE
" If you don't want ALE to run on the current Javascript file, just disable
" write on save: 'let g:ale_fix_on_save = 0'
" https://github.com/w0rp/ale
let b:ale_fixers = ['prettier', 'eslint']


