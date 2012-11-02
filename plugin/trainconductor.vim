" Vim global plugin for Train integration
" Last Change: 2012 Oct 29
" Maintainer: Phil Weir <phil@philtweir.co.uk>
" License: This file is PD

if exists("g:loaded_trainconductor")
	finish
endif
let g:loaded_trainconductor = 1

let s:save_cpo = &cpo
set cpo&vim

let s:TrainConnection = 0

if !hasmapto('<Plug>TrainconductorRedisplay')
	map <unique> <Leader>l <Plug>TrainconductorRedisplay
endif

autocmd VimLeave * call <SID>Shutdown()

autocmd VimResized * call <SID>Redisplay()

noremap <unique> <script> <Plug>TrainconductorRedisplay :call <SID>ToggleActive()<CR>

let s:current_file=expand("<sfile>")

python <<endpython
import vim, os
import lxml.etree as ET
import re

plugin_folder = os.path.realpath(os.path.dirname(os.path.abspath(vim.eval("s:current_file"))))
sys.path.insert(0, plugin_folder)

import trainconductor_vim

if vim.train is not None:
    vim.command("let s:TrainConnection = 1")
endpython

function! s:ToggleActive()
	if s:TrainConnection == 1
		python <<endpython
vim.train.toggle_active()
endpython
	endif
endfunction

function! s:Redisplay()
	if s:TrainConnection == 1
		python <<endpython
vim.train.redisplay()
endpython
	endif
endfunction

function! s:Shutdown()
	if s:TrainConnection == 1
		python <<endpython
vim.train.shutdown()
endpython
	endif
endfunction

let &cpo = s:save_cpo
