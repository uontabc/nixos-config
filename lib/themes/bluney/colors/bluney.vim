" Bluney color scheme: a blue-injected theme family (dark + light).
" Recipe: oceanic, slightly bluer — every neutral hue-shifted toward
" green, every accent a blue derivative.
"
" Two names, one file:
"   :colorscheme bluney       -> dark variant
"   :colorscheme bluney-light -> light variant (shim sets flag, sources this)
"
" termguicolors-first with cterm=256 fallbacks for every group.

if exists('syntax_on') && !exists('g:colors_name')
  syntax enable
endif
let s:light = !empty($BLUNEY_LIGHT) && $BLUNEY_LIGHT ==# '1'
let s:light = s:light || (exists('g:bluney_light') && g:bluney_light)
let s:name = s:light ? 'bluney-light' : 'bluney'
" Clear the variant flags now that they are read: otherwise loading
" :colorscheme bluney (dark) after bluney-light in the same session
" would keep the light variant active.
let $BLUNEY_LIGHT = ''
if exists('g:bluney_light')
  unlet g:bluney_light
endif
" set background BEFORE clearing/defining highlights: changing bg resets
" colorscheme state, so it must come first.
execute "set background=" . (s:light ? 'light' : 'dark')
hi clear
if exists('syntax_reset')
  let b:current_after_color = 0
endif
" set g:colors_name AFTER set background (Vim resets colorscheme state on bg change)
let g:colors_name = s:name
if has('termguicolors') || has('gui_running')
  let s:term = 1
else
  let s:term = 0
endif

" ---- palette (per variant) ----
" dark: bg #0C1F17 surface #122A1F fg #C9E4CE comment #78997F
" light: bg #F2F7EF surface #E6EFE2 fg #24382C comment #56695C
" accents (both): primary #7BD88F secondary #63C9A8 yellow #B8CC7A
"   rose #A88EA0 cyan #7FD7C4 error #C07A6E

if s:light
  let s:bg   = '#F0F5FB'
  let s:surf = '#E3EAF6'
  let s:fg   = '#1E2F45'
  let s:cm   = '#5A6F8A'
  let s:p    = '#2F6FB8'
  let s:s    = '#2F5E9E'
  let s:y    = '#7A5F1A'
  let s:r    = '#6B5AA8'
  let s:c    = '#1B6E8A'
  let s:e    = '#AE4A42'
  let s:bg_hi   = '#E3EAF6'
  let s:bor     = '#B7CBE3'
  let s:sha     = 'rgba(0,0,0,.25)'
  let s:ct_bg   = 194
  let s:ct_fg   = 59
  let s:ct_surf = 194
else
  let s:bg   = '#0E1B2E'
  let s:surf = '#152A45'
  let s:fg   = '#D5E5F2'
  let s:cm   = '#7E9BB8'
  let s:p    = '#7DBBFF'
  let s:s    = '#4F8FE0'
  let s:y    = '#E0CD97'
  let s:r    = '#B9A8E0'
  let s:c    = '#7FD7F2'
  let s:e    = '#E18B8B'
  let s:bg_hi   = '#152A45'
  let s:bor     = '#7E9BB8'
  let s:sha     = 'rgba(0,0,0,.45)'
  let s:ct_bg   = 233
  let s:ct_fg   = 151
  let s:ct_surf = 235
endif

" shared accent cterm 256 fallbacks
let s:ct_cm   = 65
let s:ct_p    = 77
let s:ct_s    = 37
let s:ct_y    = 149
let s:ct_r    = 175
let s:ct_c    = 37
let s:ct_e    = 174

" ---- helper: define a group in both guicolors and cterm ----
func! s:H(name, guifg, guibg, ctermfg, ctermbg, attr)
  let l:cmd = 'hi ' . a:name
  if s:term
    if a:guifg != 'none'
      let l:cmd .= ' guifg=' . a:guifg
    endif
    if a:guibg != 'none'
      let l:cmd .= ' guibg=' . a:guibg
    endif
  endif
  if a:ctermfg != 'none'
    let l:cmd .= ' ctermfg=' . a:ctermfg
  endif
  if a:ctermbg != 'none'
    let l:cmd .= ' ctermbg=' . a:ctermbg
  endif
  let l:cmd .= ' gui=' . a:attr . ' cterm=' . a:attr
  exe l:cmd
endfunc

" ---- editor UI ----
call s:H('Normal', s:fg, s:bg, s:ct_fg, s:ct_bg, 'none')
call s:H('NormalNC', s:fg, s:bg, s:ct_fg, s:ct_bg, 'none')
call s:H('CursorLine', 'none', s:bg_hi, 'none', s:ct_surf, 'none')
call s:H('LineNr', s:cm, s:bg, s:ct_cm, s:ct_bg, 'none')
call s:H('CursorLineNr', s:p, s:bg, s:ct_p, s:ct_bg, 'bold')
call s:H('SignColumn', s:cm, s:bg, s:ct_cm, s:ct_bg, 'none')
call s:H('VertSplit', s:cm, s:cm, s:ct_cm, s:ct_cm, 'none')
call s:H('WinSeparator', s:cm, 'none', s:ct_cm, 'none', 'none')
call s:H('StatusLine', s:fg, s:bg_hi, s:ct_fg, s:ct_surf, 'none')
call s:H('StatusLineNC', s:cm, s:bg, s:ct_cm, s:ct_bg, 'none')
call s:H('TabLine', s:fg, s:surf, s:ct_fg, s:ct_surf, 'none')
call s:H('TabLineSel', s:bg, s:p, s:ct_bg, s:ct_p, 'bold')
call s:H('TabLineFill', s:cm, s:bg, s:ct_cm, s:ct_bg, 'none')
call s:H('Pmenu', s:fg, s:bg_hi, s:ct_fg, s:ct_surf, 'none')
call s:H('PmenuSel', s:bg, s:p, s:ct_bg, s:ct_p, 'bold')
call s:H('PmenuSbar', s:fg, s:surf, s:ct_fg, s:ct_surf, 'none')
call s:H('PmenuThumb', s:cm, s:cm, s:ct_cm, s:ct_cm, 'none')
call s:H('Visual', s:bg, s:p, s:ct_bg, s:ct_p, 'none')
call s:H('VisualNOS', s:bg, s:p, s:ct_bg, s:ct_p, 'none')
call s:H('Search', s:bg, s:y, s:ct_bg, s:ct_y, 'none')
call s:H('IncSearch', s:bg, s:c, s:ct_bg, s:ct_c, 'none')
call s:H('MatchParen', s:bg, s:y, s:ct_bg, s:ct_y, 'bold')
call s:H('Folded', s:cm, s:bg_hi, s:ct_cm, s:ct_surf, 'none')
call s:H('FoldColumn', s:cm, s:bg, s:ct_cm, s:ct_bg, 'none')
call s:H('ErrorMsg', s:bg, s:e, s:ct_bg, s:ct_e, 'bold')
call s:H('Todo', s:bg, s:y, s:ct_bg, s:ct_y, 'bold')
call s:H('SpecialKey', s:cm, s:bg, s:ct_cm, s:ct_bg, 'none')
call s:H('Title', s:p, 'none', s:ct_p, 'none', 'bold')
call s:H('Tag', s:p, 'none', s:ct_p, 'none', 'none')
call s:H('Moved', s:y, 'none', s:ct_y, 'none', 'none')
call s:H('ModeMsg', s:p, 'none', s:ct_p, 'none', 'bold')
call s:H('MsgArea', s:fg, s:bg, s:ct_fg, s:ct_bg, 'none')
call s:H('Question', s:e, 'none', s:ct_e, 'none', 'none')
call s:H('MoreMsg', s:p, 'none', s:ct_p, 'none', 'none')
call s:H('WarningMsg', s:e, 'none', s:ct_e, 'none', 'none')

" ---- diff ----
call s:H('DiffAdd', s:bg, s:p, s:ct_bg, s:ct_p, 'none')
call s:H('DiffChange', s:bg, s:c, s:ct_bg, s:ct_c, 'none')
call s:H('DiffDelete', s:bg, s:e, s:ct_bg, s:ct_e, 'none')
call s:H('DiffText', s:bg, s:y, s:ct_bg, s:ct_y, 'none')

" ---- health (Neovim :checkhealth) ----
call s:H('healthSuccess', s:p, 'none', s:ct_p, 'none', 'none')
call s:H('healthError', s:e, 'none', s:ct_e, 'none', 'none')
call s:H('healthWarning', s:y, 'none', s:ct_y, 'none', 'none')
call s:H('healthInfo', s:c, 'none', s:ct_c, 'none', 'none')

" ---- Neovim floats ----
call s:H('NormalFloat', s:fg, s:surf, s:ct_fg, s:ct_surf, 'none')
call s:H('FloatBorder', s:cm, s:surf, s:ct_cm, s:ct_surf, 'none')
hi! link NormalFloatShadow NormalFloat

" ---- syntax ----
call s:H('Comment', s:cm, 'none', s:ct_cm, 'none', 'italic')
call s:H('Constant', s:r, 'none', s:ct_r, 'none', 'none')
call s:H('String', s:p, 'none', s:ct_p, 'none', 'none')
call s:H('Character', s:r, 'none', s:ct_r, 'none', 'none')
call s:H('Number', s:c, 'none', s:ct_c, 'none', 'none')
call s:H('Boolean', s:c, 'none', s:ct_c, 'none', 'bold')
call s:H('Float', s:c, 'none', s:ct_c, 'none', 'none')
call s:H('Identifier', s:fg, 'none', s:ct_fg, 'none', 'none')
call s:H('Function', s:s, 'none', s:ct_s, 'none', 'bold')
call s:H('Keyword', s:p, 'none', s:ct_p, 'none', 'bold')
call s:H('Statement', s:p, 'none', s:ct_p, 'none', 'bold')
call s:H('Conditional', s:p, 'none', s:ct_p, 'none', 'bold')
call s:H('Repeat', s:p, 'none', s:ct_p, 'none', 'bold')
call s:H('Label', s:r, 'none', s:ct_r, 'none', 'none')
call s:H('Operator', s:y, 'none', s:ct_y, 'none', 'none')
call s:H('Type', s:c, 'none', s:ct_c, 'none', 'none')
call s:H('Typedef', s:c, 'none', s:ct_c, 'none', 'bold')
call s:H('Structure', s:c, 'none', s:ct_c, 'none', 'none')
call s:H('StorageClass', s:c, 'none', s:ct_c, 'none', 'bold')
call s:H('PreProc', s:r, 'none', s:ct_r, 'none', 'none')
call s:H('PreCondit', s:r, 'none', s:ct_r, 'none', 'none')
call s:H('Include', s:r, 'none', s:ct_r, 'none', 'none')
call s:H('Define', s:r, 'none', s:ct_r, 'none', 'none')
call s:H('Macro', s:r, 'none', s:ct_r, 'none', 'none')
call s:H('Special', s:y, 'none', s:ct_y, 'none', 'none')
call s:H('SpecialChar', s:e, 'none', s:ct_e, 'none', 'none')
call s:H('SpecialComment', s:cm, 'none', s:ct_cm, 'none', 'italic')
call s:H('Debug', s:e, 'none', s:ct_e, 'none', 'none')
call s:H('DebugToPassed', s:p, 'none', s:ct_p, 'none', 'none')
call s:H('DebugFail', s:e, 'none', s:ct_e, 'none', 'none')
call s:H('Error', s:bg, s:e, s:ct_bg, s:ct_e, 'bold')

" ---- Tree-sitter captures ----
" silent! suppresses W18 in Vim 9 (Neovim supports '@' dotted names)
silent! call s:H('@variable', s:fg, 'none', s:ct_fg, 'none', 'none')
silent! call s:H('@variable.builtin', s:r, 'none', s:ct_r, 'none', 'none')
silent! call s:H('@variable.parameter', s:r, 'none', s:ct_r, 'none', 'none')
silent! call s:H('@variable.functional', s:s, 'none', s:ct_s, 'none', 'none')
silent! call s:H('@comment', s:cm, 'none', s:ct_cm, 'none', 'italic')
silent! call s:H('@comment.error', s:e, 'none', s:ct_e, 'none', 'italic')
silent! call s:H('@comment.warning', s:y, 'none', s:ct_y, 'none', 'italic')
silent! call s:H('@comment.note', s:c, 'none', s:ct_c, 'none', 'italic')
silent! call s:H('@comment.todo', s:bg, s:y, s:ct_bg, s:ct_y, 'bold')
silent! call s:H('@string', s:p, 'none', s:ct_p, 'none', 'none')
silent! call s:H('@string.regexp', s:e, 'none', s:ct_e, 'none', 'none')
silent! call s:H('@string.escape', s:c, 'none', s:ct_c, 'none', 'none')
silent! call s:H('@string.special', s:y, 'none', s:ct_y, 'none', 'none')
silent! call s:H('@string.special.symbol', s:c, 'none', s:ct_c, 'none', 'none')
silent! call s:H('@character', s:r, 'none', s:ct_r, 'none', 'none')
silent! call s:H('@number', s:c, 'none', s:ct_c, 'none', 'none')
silent! call s:H('@boolean', s:c, 'none', s:ct_c, 'none', 'bold')
silent! call s:H('@float', s:c, 'none', s:ct_c, 'none', 'none')
silent! call s:H('@function', s:s, 'none', s:ct_s, 'none', 'bold')
silent! call s:H('@function.builtin', s:y, 'none', s:ct_y, 'none', 'bold')
silent! call s:H('@function.macro', s:p, 'none', s:ct_p, 'none', 'bold')
silent! call s:H('@function.conditional', s:p, 'none', s:ct_p, 'none', 'bold')
silent! call s:H('@keyword', s:p, 'none', s:ct_p, 'none', 'bold')
silent! call s:H('@keyword.directive', s:r, 'none', s:ct_r, 'none', 'none')
silent! call s:H('@keyword.import', s:r, 'none', s:ct_r, 'none', 'none')
silent! call s:H('@keyword.modifier', s:c, 'none', s:ct_c, 'none', 'none')
silent! call s:H('@keyword.repeat', s:p, 'none', s:ct_p, 'none', 'bold')
silent! call s:H('@keyword.conditional', s:p, 'none', s:ct_p, 'none', 'bold')
silent! call s:H('@type', s:c, 'none', s:ct_c, 'none', 'none')
silent! call s:H('@type.builtin', s:c, 'none', s:ct_c, 'none', 'none')
silent! call s:H('@type.primitive', s:c, 'none', s:ct_c, 'none', 'none')
silent! call s:H('@constant', s:r, 'none', s:ct_r, 'none', 'none')
silent! call s:H('@constant.builtin', s:c, 'none', s:ct_c, 'none', 'none')
silent! call s:H('@constant.macro', s:y, 'none', s:ct_y, 'none', 'none')
silent! call s:H('@namespace', s:fg, 'none', s:ct_fg, 'none', 'none')
silent! call s:H('@module', s:fg, 'none', s:ct_fg, 'none', 'none')
silent! call s:H('@property', s:r, 'none', s:ct_r, 'none', 'none')
silent! call s:H('@parameter', s:r, 'none', s:ct_r, 'none', 'none')
silent! call s:H('@text', s:fg, 'none', s:ct_fg, 'none', 'none')
silent! call s:H('@text.strong', s:fg, 'none', s:ct_fg, 'none', 'bold')
silent! call s:H('@text.emphasis', s:fg, 'none', s:ct_fg, 'none', 'italic')
silent! call s:H('@text.literal', s:p, 'none', s:ct_p, 'none', 'none')
silent! call s:H('@text.uri', s:c, 'none', s:ct_c, 'none', 'underline')
silent! call s:H('@text.todo', s:bg, s:y, s:ct_bg, s:ct_y, 'bold')
silent! call s:H('@text.note', s:c, 'none', s:ct_c, 'none', 'none')
silent! call s:H('@text.warning', s:y, 'none', s:ct_y, 'none', 'none')
silent! call s:H('@text.error', s:e, 'none', s:ct_e, 'none', 'none')
silent! call s:H('@text.diff.add', s:bg, s:p, s:ct_bg, s:ct_p, 'none')
silent! call s:H('@text.diff.delete', s:bg, s:e, s:ct_bg, s:ct_e, 'none')
silent! call s:H('@text.diff.change', s:bg, s:c, s:ct_bg, s:ct_c, 'none')
silent! call s:H('@text.diff.end', s:bg, s:y, s:ct_bg, s:ct_y, 'none')

" ---- links (silent! suppresses W18 in Vim 9; no-op in Neovim) ----
silent! hi! link @text.literal String
silent! hi! link @text.quote String
silent! hi! link @text.uri String
silent! hi! link @text.strong Bold
silent! hi! link @constant.builtin Boolean
" ---- end ----
unlet s:term
let g:bluney_loaded = 1
