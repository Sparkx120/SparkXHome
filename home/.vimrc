" ~/.vimrc (configuration file for vim only)
set nocompatible              " be iMproved, required
filetype off                  " required

" Airline
set laststatus=2
let g:airline_theme           = 'powerlineish'
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1

" skeletons
function! SKEL_spec()
	0r /usr/share/vim/current/skeletons/skeleton.spec
	language time en_US
	let login = system('whoami')
	if v:shell_error
	   let login = 'unknown'
	else
	   let newline = stridx(login, "\n")
	   if newline != -1
		let login = strpart(login, 0, newline)
	   endif
	endif
	let hostname = system('hostname -f')
	if v:shell_error
	    let hostname = 'localhost'
	else
	    let newline = stridx(hostname, "\n")
	    if newline != -1
		let hostname = strpart(hostname, 0, newline)
	    endif
	endif
	exe "%s/specRPM_CREATION_DATE/" . strftime("%a\ %b\ %d\ %Y") . "/ge"
	exe "%s/specRPM_CREATION_AUTHOR_MAIL/" . login . "@" . hostname . "/ge"
	exe "%s/specRPM_CREATION_NAME/" . expand("%:t:r") . "/ge"
endfunction
autocmd BufNewFile	*.spec	call SKEL_spec()

" Remove all trailing whitespace by pressing F5
" https://vi.stackexchange.com/questions/454/whats-the-simplest-way-to-strip-trailing-whitespace-from-all-lines-in-a-file
nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" Tab Configuration
set tabstop=4
set softtabstop=0
set expandtab
set shiftwidth=4
set smarttab

" Color Settings
set t_Co=256
set background=dark
highlight Normal ctermbg=NONE
highlight nonText ctermbg=NONE
colorscheme fu

"NERDTree
let g:NERDTreeWinSize=40
let g:NERDTreeShowHidden=1
"autocmd! VimEnter * NERDTree

" NERDTree (only start if no file given)
"autocmd StdinReadPre * let s:std_in=1
"autocmd! VimEnter * if argc() == 0 && !exists('s:std_in') && v:this_session == '' | NERDTree | endif
" Exit Vim if NERDTree is the only window remaining in the only tab.
"autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
let g:NERDTreeNodeDelimiter = "\u00a0"

" Minimap
"autocmd! VimEnter * Minimap

" ALE
let g:ale_fixers = ["prettier", "tslint"]

" Mouse
set mouse=a

" Backspace
set backspace=indent,eol,start

" Syntax Highlighting
syntax on

" Reenable filetype
filetype on
filetype plugin on
