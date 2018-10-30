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

"Press <leader><space> to turn off search highlight
nnoremap <leader><space> :nohlsearch<CR>

"Set smart indent
"set cindent

"Specifies indentation behaviour for C like languages
"j1 adds support for lambda indentations (Java like)
"i-s sets the initialiser in constructors correctly
setlocal cindent cino=j1,(0,ws,Ws

let clang_format = $HOME."/bin/clang-format.py"
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

"Disables arrow keys
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>
inoremap <Up> <NOP>
inoremap <Down> <NOP>
inoremap <Left> <NOP>
inoremap <Right> <NOP>

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

"maps the jj key succession to escape because esc is too far to reach
imap jj <Esc>

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

" VUNDLE
" " set the runtime path to include Vundle and initialize
" set rtp+=~/.vim/bundle/Vundle.vim
" call vundle#begin()
"   " alternatively, pass a path where Vundle should install plugins
"   "call vundle#begin('~/some/path/here')
" 
"   " let Vundle manage Vundle, required
"   Plugin 'VundleVim/Vundle.vim'
"   Plugin 'scrooloose/nerdcommenter'
"   Plugin 'elmcast/elm-vim'
"   Bundle 'captbaritone/better-indent-support-for-php-with-html'
" 
"   " All of your Plugins must be added before the following line
"   call vundle#end()            " required
"   filetype plugin indent on    " required
"   " To ignore plugin indent changes, instead use:
"   "filetype plugin on
"   "
"   " Brief help
"   " :PluginList       - lists configured plugins
"   " :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
"   " :PluginSearch foo - searches for foo; append `!` to refresh local cache
"   " :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"   "
"   " see :h vundle for more details or wiki for FAQ
"   " Put your non-Plugin stuff after this line

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

"SCORTEX settings BEGIN

"Set tabs width to 2
set shiftwidth=2
set tabstop=2
set softtabstop=2

"Set tabs width to 4 for Javascript and Python files
autocmd FileType python,javascript setlocal shiftwidth=4 tabstop=4

"Autoexpands tabs
set expandtab

"Deactivates expandtab for makefiles
autocmd FileType make setlocal noexpandtab

"Prints the Scortex header whenever you open a new file
function! s:insert_header()
  execute "normal! i/**"
  execute "normal! o\<BS> Copyright (c) 2017 Scortex SAS"
  execute "normal! o/"
  normal! o
endfunction
"autocmd BufNewFile *.{h,c,hpp,cpp,js} call <SID>insert_header()

function! s:insert_header_py()
  execute "normal! i\"\"\""
  execute "normal! oCopyright (c) 2017 Scortex SAS"
  execute "normal! o\"\"\""
  normal! o
endfunction
"autocmd BufNewFile *.{py} call <SID>insert_header_py()

function! s:insert_header_make()
  execute "normal! i#"
  execute "normal! o# Copyright (c) 2017 Scortex SAS"
  execute "normal! o#"
  normal! o
endfunction
"autocmd BufNewFile ?akefile* call <SID>insert_header_make()

"SCORTEX settings END
