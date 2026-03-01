" Name:         blarkdue (Base16 Adjusted)
" Description:  Adapted from darkblue to match mini.base16 palette

set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = 'screenofdeath'

if (has('termguicolors') && &termguicolors) || has('gui_running')
  " Terminal ANSI colors based on the palette
  let g:terminal_ansi_colors = [
        \ '#000050', '#dfe2f1', '#6cc254', '#2ac3de',
        \ '#dbcd00', '#ff9e64', '#7aa2f7', '#d1d4dc',
        \ '#6887da', '#dfe2f1', '#6cc254', '#2ac3de',
        \ '#dbcd00', '#ff9e64', '#7aa2f7', '#9d7cd8']

  " --- UI Highlights ---
  hi Normal          guifg=#d1d4dc guibg=#000050 gui=NONE
  hi Cursor          guifg=#000050 guibg=#d1d4dc gui=NONE
  hi CursorLine      guifg=NONE    guibg=#000039 gui=NONE
  hi CursorLineNr    guifg=#2ac3de guibg=#000039 gui=bold
  hi ColorColumn     guifg=NONE    guibg=#292e42 gui=NONE
  hi Folded          guifg=#6887da guibg=#000039 gui=italic
  hi LineNr          guifg=#6887da guibg=#000039 gui=NONE
  hi MatchParen      guifg=#000050 guibg=#6887da gui=bold
  hi Pmenu           guifg=#d1d4dc guibg=#000039 gui=NONE
  hi PmenuSel        guifg=#000039 guibg=#d1d4dc gui=NONE
  hi Search          guifg=#000050 guibg=#2ac3de gui=NONE
  hi IncSearch       guifg=#000050 guibg=#c76b29 gui=NONE
  hi StatusLine      guifg=#dfe2f1 guibg=#292e42 gui=NONE
  hi StatusLineNC    guifg=#6887da guibg=#000039 gui=NONE
  hi VertSplit       guifg=#292e42 guibg=#292e42 gui=NONE
  hi Visual          guifg=NONE    guibg=#292e42 gui=NONE
  hi EndOfBuffer     guifg=#000050 guibg=NONE    gui=NONE

  " --- Syntax Highlights ---
  hi Comment         guifg=#6887da guibg=NONE    gui=italic
  hi Constant        guifg=#c76b29 guibg=NONE    gui=NONE
  hi String          guifg=#6cc254 guibg=NONE    gui=NONE
  hi Identifier      guifg=#dfe2f1 guibg=NONE    gui=NONE
  hi Function        guifg=#dbcd00 guibg=NONE    gui=NONE
  hi Statement       guifg=#ff9e64 guibg=NONE    gui=NONE
  hi PreProc         guifg=#2ac3de guibg=NONE    gui=NONE
  hi Type            guifg=#2ac3de guibg=NONE    gui=NONE
  hi Special         guifg=#7aa2f7 guibg=NONE    gui=NONE
  hi Underlined      guifg=#dbcd00 guibg=NONE    gui=underline
  hi Error           guifg=#dfe2f1 guibg=#fc0734 gui=bold
  hi Todo            guifg=#ff9e64 guibg=#000039 gui=bold

  " --- Custom Flash Integration ---
  hi FlashLabel      guifg=#ffffff guibg=#fc0734 gui=bold

  " --- Diff Groups ---
  hi DiffAdd         guifg=#000050 guibg=#6cc254 gui=NONE
  hi DiffChange      guifg=#000050 guibg=#ff9e64 gui=NONE
  hi DiffDelete      guifg=#000050 guibg=#dfe2f1 gui=NONE
  hi DiffText        guifg=#000050 guibg=#7aa2f7 gui=NONE

  " --- Legacy/CTerm Fallbacks (256 color) ---
  if &t_Co >= 256
    hi Normal       ctermfg=188 ctermbg=17  cterm=NONE
    hi CursorLine   ctermfg=NONE ctermbg=18 cterm=NONE
    hi Statement    ctermfg=209 ctermbg=NONE cterm=NONE
    hi Comment      ctermfg=68  ctermbg=NONE cterm=NONE
    hi Constant     ctermfg=166 ctermbg=NONE cterm=NONE
    hi Type         ctermfg=45  ctermbg=NONE cterm=NONE
  endif
endif
