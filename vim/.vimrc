"Disables compatibility with vi
set nocompatible

"Prints line numbers
set number

"Updates the window title
set title

"Prints the cursor position
set ruler

"Sets syntaxing coloring
syntax on

"Prints a minimum of 3 lines around cursor
set scrolloff=3

"Sets color theme
colorscheme Tomorrow-Night

if &term =~ '256color'
  " Disable Background Color Erase (BCE) so that color schemes
  " work properly when Vim is used inside tmux and GNU screen.
  set t_ut=
endif

"Set autoplete mode to zshlike
set wildmode=longest:full,full

"Visual autocomplete for command menu
set wildmenu

"Colors all matches on search
set hlsearch

"Search as characters are entered
set incsearch

"Set smart indent
"set cindent

"Specifies indentation behaviour for C like languages
"j1 adds support for lambda indentations (Java like)
"i-s sets the initialiser in constructors correctly
setlocal cindent cino=j1,(0,ws,Ws

let clang_format = "/usr/share/clang/clang-format.py"
if filereadable(clang_format)
  "Launches clang-format syntax checker upon entering Control-K
  execute "map <C-K> :pyf ".clang_format."<cr>"
  execute "imap <C-K> <c-o>:pyf ".clang_format."<cr>"

  "Launches clang-format syntax checker upon saving
  function! Formatonsave()
    let l:formatdiff = 1
    execute "pyf ".g:clang_format
  endfunction
  autocmd BufWritePre *.h,*.hpp,*.c,*.cpp call Formatonsave()
endif

"removes case for common save and quit ex commands
"Sets some uppercase commands to the lowercase equivalent
"command WQ wq
"command Wq wq
"command W w
"command Q q
"command WA wa
"command Wa wa
"command QA qa
"command Qa qa

"Allows backspacing over newlines, indents, start of insert
"set backspace=eol,indent,start
set backspace=eol,indent

"Changes the line numbers to be referent to current line
set rnu

"Highlight current line
set cursorline

"Set colorcolumn color to grey
highlight ColorColumn ctermbg=8

"Highlights the column 81
set colorcolumn=81

"Read scons files (SConstruct, SConscript) as python files
autocmd BufNewFile,BufRead SCons* set filetype=python

" TAGS
au BufNewFile,BufRead,BufEnter *.cpp,*.hpp set omnifunc=omni#cpp#complete#Main
" configure tags - add additional tags here or comment out not-used ones
set tags+=~/.vim/tags/cpp
" build tags of your own project with Ctrl-F12
map <C-F12> :!ctags -R --sort=yes --c++-kinds=+p --fields=+iaS --extra=+q .<CR>

" OmniCppComplete
let OmniCpp_NamespaceSearch = 1
let OmniCpp_GlobalScopeSearch = 1
let OmniCpp_ShowAccess = 1
let OmniCpp_ShowPrototypeInAbbr = 1 " show function parameters
let OmniCpp_MayCompleteDot = 1 " autocomplete after .
let OmniCpp_MayCompleteArrow = 1 " autocomplete after ->
let OmniCpp_MayCompleteScope = 1 " autocomplete after ::
let OmniCpp_DefaultNamespaces = ["std", "_GLIBCXX_STD"]
" automatically open and close the popup menu / preview window
au CursorMovedI,InsertLeave * if pumvisible() == 0|silent! pclose|endif
set completeopt=menuone,menu,longest,preview

"Set tabs width to 2
set shiftwidth=2
set tabstop=2
set softtabstop=2

"Set tabs width to 4 for Python files
autocmd FileType python setlocal shiftwidth=4 tabstop=4

"Autoexpands tabs
set expandtab

"Deactivates expandtab for makefiles
autocmd FileType make setlocal noexpandtab

"Enables dash (-) in C-n autocompletion
set iskeyword+=\-

" Refreshes GitGutter every 100ms
set updatetime=100

" NERDTree toggle
map <leader>n :NERDTreeToggleVCS<CR>

" Remove trailing whitespaces on save
autocmd BufWritePre,FileWritePre * %s/\s\+$//e

" Activate mouse for all modes
set mouse=a
