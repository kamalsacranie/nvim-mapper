" Prevent loading plugin twice
if exists('g:nvim-mapper') | finish | endif

" let s:save_cpo = &cpo
" set cpo&vim

if !has('nvim')
  echohl Error
  echom "Sorry this plugin only works with neovim version that support lua"
  echohl clear
  finish
endif

" lua require'mapper'.setup()
let g:nvim_mapper_loaded = 1

" Create vim command
" command! JestTest :lua require'jest-tester'.test()

" let &cpo = s:save_cpo
" unlet s:save_cpo
