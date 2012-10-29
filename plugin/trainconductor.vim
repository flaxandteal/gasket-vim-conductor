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

autocmd VimEnter * call <SID>Startup()
autocmd VimLeave * call <SID>Shutdown()

autocmd BufEnter * call <SID>Redisplay()
autocmd BufRead * call <SID>Redisplay()
autocmd VimResized * call <SID>Redisplay()
autocmd CursorMoved * call <SID>Redisplay()
autocmd CursorMovedI * call <SID>Redisplay()

noremap <unique> <script> <Plug>TrainconductorRedisplay :call <SID>ToggleActive()<CR>

function! s:Startup()
python <<endpython
import vim, os, socket
import lxml.etree as ET
import re

class TrainTrain:
    active = False
    def __init__(self, train_track_file):
        try:
            track = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
	    track.connect(train_track_file)
	except:
	    self.track = None
        finally:
            self.track = track

    def toggle_active(self):
        self.active = not self.active
	self.redisplay()

    def redisplay(self):
	track = self.track
        if track is None:
		return

        if not self.active:
		self.clear()
		return

        doc = ET.Element('svg', width='10', height='10', xmlns='http://www.w3.org/2000/svg')

	start = max(vim.current.range.start - 50, 0)
        end = min(len(vim.current.buffer), start + 100)
	lines = vim.current.buffer[start:end]
	search_term = vim.eval("@/")

	if len(lines) > 1:
	    y = 0
	    x = vim.current.window.width - 12
            height = .2
	    longest_line = max(*map(len, vim.current.buffer))
	    ratio = 10. / longest_line
	    opacity = 0.5
	    for linec in range(len(lines)):
		line = lines[linec]
		whitespace = (len(line) - len(line.lstrip())) * ratio
		width = (len(line)) * ratio
		y += height
		
		if vim.current.range.start <= start + linec and\
	           vim.current.range.end >= start + linec:
			line_colour = (255, 255, 255)
		else:
			line_colour = (255, 0, 0)
		found_colour = tuple(map(lambda x:int(255-.25*(255-x)), line_colour))

	        ET.SubElement(doc, 'rect', x=str(x), y=str(y), width='1', height=str(height),
		    **{'fill' : 'rgb(255, 255, 0)', 'fill-opacity' : str(opacity)})
	        ET.SubElement(doc, 'rect', x=str(x + 1), y=str(y), width=str(whitespace), height=str(height),
		    **{'fill' : 'rgb' + str(line_colour) + '', 'fill-opacity' : str(opacity/2)})
	        ET.SubElement(doc, 'rect', x=str(x + 1 + whitespace), y=str(y), width=str(width-whitespace), height=str(height),
		    **{'fill' : 'rgb' + str(line_colour) + '', 'fill-opacity' : str(opacity)})

		if search_term:
		    matches = re.finditer(search_term, line)
		    for match in matches:
			offset = x + 1 + match.start() * ratio
			width = (match.end() - match.start()) * ratio
			ET.SubElement(doc, 'rect', x=str(offset), y=str(y), width=str(width), height=str(height),
		            **{'fill' : 'rgb' + str(found_colour) + '', 'fill-opacity' : str(opacity)})

        track.sendall(ET.tostring(doc))
        track.sendall("\n__TRAIN_CABOOSE__\n")

    def shutdown(self):
	track = self.track
        if track is None:
		return

        self.clear()
	track.close()

    def clear(self):
	track = self.track
        if track is None:
		return

        track.sendall("\n__TRAIN_CABOOSE__\n")
        track.sendall("\n__TRAIN_CABOOSE__\n")

train_track_file = os.getenv("TRAIN_SOCKET")
if train_track_file is not None and train_track_file != "":
    vim.command("let s:TrainConnection = 1")
    train_train = TrainTrain(train_track_file)
endpython
endfunction

function! s:ToggleActive()
	if s:TrainConnection == 1
		python <<endpython
train_train.toggle_active()
endpython
	endif
endfunction

function! s:Redisplay()
	if s:TrainConnection == 1
		python <<endpython
train_train.redisplay()
endpython
	endif
endfunction

function! s:Shutdown()
	if s:TrainConnection == 1
		python <<endpython
train_train.shutdown()
endpython
	endif
endfunction

let &cpo = s:save_cpo
