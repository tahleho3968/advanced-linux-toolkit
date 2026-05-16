" ============================================================
" Advanced Linux Toolkit - Vim Configuration
" Enhanced vim settings for development and system administration
" ============================================================

" ------------------------------
" General Settings
" ------------------------------
set nocompatible              " Use Vim defaults (not Vi)
set history=1000              " Keep 1000 lines of command line history
set undolevels=1000           " Keep 1000 levels of undo
set mouse=a                   " Enable mouse support
set clipboard=unnamedplus     " Use system clipboard
set encoding=utf-8            " Set default encoding
set fileencoding=utf-8        " Default file encoding
set fileformats=unix,dos,mac  " Auto-detect line endings

" ------------------------------
" UI Settings
" ------------------------------
syntax on                     " Enable syntax highlighting
set number                    " Show line numbers
set relativenumber            " Show relative line numbers
set cursorline                " Highlight current line
set showmatch                 " Show matching brackets
set matchtime=2               " How long to show matching brackets
set ruler                     " Show cursor position
set title                     " Show title in terminal
set showcmd                   " Show commands in status line
set wildmenu                  " Enhanced command line completion
set wildmode=longest:full,full
set laststatus=2              " Always show status line
set list                      " Show invisible characters
set listchars=tab:▸\ ,trail:·,eol:¬,nbsp:_
set t_Co=256                  " Use 256 colors

" ------------------------------
" Search Settings
" ------------------------------
set hlsearch                  " Highlight search results
set incsearch                 " Incremental search
set ignorecase                " Ignore case when searching
set smartcase                 " Override ignorecase if pattern contains uppercase
set gdefault                  " Add the g flag by default to :s

" ------------------------------
" Indentation Settings
" ------------------------------
set autoindent                " Auto indent
set smartindent               " Smart indenting
set tabstop=4                 " Number of spaces that a <Tab> counts for
set shiftwidth=4              " Number of spaces to use for autoindent
set softtabstop=4             " Number of spaces that a <Tab> counts for while editing
set expandtab                 " Use spaces instead of tabs
set smarttab                  " Smart tab handling

" ------------------------------
" File Type Specific Settings
" ------------------------------
filetype on                   " Enable filetype detection
filetype plugin on            " Enable filetype plugins
filetype indent on            " Enable filetype indentation

" Language-specific settings
autocmd FileType python setlocal shiftwidth=4 tabstop=4 expandtab
autocmd FileType sh,bash setlocal shiftwidth=2 tabstop=2 expandtab
autocmd FileType yaml setlocal shiftwidth=2 tabstop=2 expandtab
autocmd FileType json setlocal shiftwidth=2 tabstop=2 expandtab
autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 expandtab
autocmd FileType html,css setlocal shiftwidth=2 tabstop=2 expandtab
autocmd FileType perl setlocal shiftwidth=4 tabstop=4 expandtab

" ------------------------------
" Visual Enhancements
" ------------------------------
" Line number colors
highlight LineNr ctermfg=240
highlight CursorLineNr ctermfg=cyan

" Status line
set statusline=
set statusline+=%#PmenuSel#
set statusline+=%{&paste?'[PASTE]':''}
set statusline+=%#LineNr#
set statusline+=\ %F%m%r%h%w%y
set statusline+=%=
set statusline+=%{&fileencoding?&fileencoding:&encoding}
set statusline+=\[%{&fileformat}\]
set statusline+=\ %p%%
set statusline+=\ %l:%c
set statusline+=\ %L

" ------------------------------
" Folding Settings
" ------------------------------
set foldenable                " Enable folding
set foldmethod=indent         " Fold based on indent
set foldlevel=99              " Don't fold by default
set foldcolumn=1              " Show fold column

" ------------------------------
" Whitespace and Tabs
" ------------------------------
" Highlight trailing whitespace
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

" Remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" ------------------------------
" Backup and Swap Files
" ------------------------------
set backup
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//
set undodir=~/.vim/undo//
set backupskip=/tmp/*,/private/tmp/*

" Create directories if they don't exist
if !isdirectory(expand("~/.vim/backup"))
    call mkdir(expand("~/.vim/backup"), "p")
endif
if !isdirectory(expand("~/.vim/swap"))
    call mkdir(expand("~/.vim/swap"), "p")
endif
if !isdirectory(expand("~/.vim/undo"))
    call mkdir(expand("~/.vim/undo"), "p")
endif

" ------------------------------
" Key Mappings
" ------------------------------
" Leader key
let mapleader = ","

" Quick save
nnoremap <Leader>w :w<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>x :x<CR>

" Quick quit all
nnoremap <Leader>qa :qa<CR>

" Clear search highlight
nnoremap <Leader>n :nohlsearch<CR>

" Toggle relative line numbers
nnoremap <Leader>r :set relativenumber!<CR>

" Edit vimrc
nnoremap <Leader>ev :vsplit $MYVIMRC<CR>

" Source vimrc
nnoremap <Leader>sv :source $MYVIMRC<CR>

" Buffer navigation
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprev<CR>

" Split navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Resize splits
nnoremap <Leader>+ :resize +5<CR>
nnoremap <Leader>- :resize -5<CR>
nnoremap <Leader>> :vertical resize +5<CR>
nnoremap <Leader>< :vertical resize -5<CR>

" Copy to system clipboard
vnoremap <Leader>y "+y
nnoremap <Leader>Y "+yg_
nnoremap <Leader>y "+y

" Paste from system clipboard
nnoremap <Leader>p "+p
nnoremap <Leader>P "+P
vnoremap <Leader>p "+p
vnoremap <Leader>P "+P

" Move lines
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" Duplicate line
nnoremap <Leader>d yyp

" Comment line
nnoremap <Leader>c :Commentary<CR>
vnoremap <Leader>c :Commentary<CR>

" ------------------------------
" Plugin Settings (if plugins are installed)
" ------------------------------
" NERDTree
nnoremap <Leader>nt :NERDTreeToggle<CR>
nnoremap <Leader>nf :NERDTreeFind<CR>

" CtrlP
let g:ctrlp_map = '<Leader>p'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_custom_ignore = {
    \ 'dir': '\v[\/]\.(git|hg|svn|node_modules|venv|__pycache__)$',
    \ 'file': '\v\.(exe|so|dll|pyc|o|class)$',
    \ }

" Syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" ------------------------------
" Auto-Commands
" ------------------------------
" Remember last position
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" Auto source vimrc on save
augroup autosourcing
    autocmd!
    autocmd BufWritePost .vimrc source %
augroup END

" Set filetype for common files
au BufRead,BufNewFile *.md set filetype=markdown
au BufRead,BufNewFile *.yaml,*.yml set filetype=yaml
au BufRead,BufNewFile Dockerfile* set filetype=dockerfile
au BufRead,BufNewFile *.log set filetype=log

" ------------------------------
" Helpers
" ------------------------------
" Show current syntax highlighting group
map <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

" Trim trailing whitespace on save for specific filetypes
autocmd BufWritePre *.py,*.sh,*.bash,*.pl,*.cpp,*.c,*.h :%s/\s\+$//e

" ------------------------------
" End of Vim Configuration
" ------------------------------
