" Disables arrow keys
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>
inoremap <Up> <NOP>
inoremap <Down> <NOP>
inoremap <Left> <NOP>
inoremap <Right> <NOP>

" Bind Y to be coherent with D and C
" Multi-mode mappings (Normal, Visual, Operating-pending modes).
noremap Y y$

" Binds C-{hjkl} to window switching
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Press <leader><space> to turn off search highlight
nnoremap <leader><space> :nohlsearch<CR>

" Maps the jj key succession to escape because esc is too far to reach
imap jj <Esc>

" Allow saving of files as sudo when I forgot to start vim using sudo.
" Source: https://stackoverflow.com/questions/2600783/how-does-the-vim-write-with-sudo-trick-work
cmap w!! w !sudo tee > /dev/null %
