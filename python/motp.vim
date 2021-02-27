function! MotpGetPass()
  if $fkey == ''
    :let $fkey=inputsecret("fkey:")
  endif
endfun

augroup FER
  au!

  au BufReadPost *.motp
    \ :call MotpGetPass()
    \|:setl viminfo= noswapfile noundofile nobackup
    \|:silent 1,$ !python motp.py --filedec - - $fkey

  au BufWritePre *.motp
    \ :call MotpGetPass()
    \|:setl viminfo= noswapfile noundofile nobackup
    \|:silent 1,$ !python motp.py --fileenc - - $fkey

augroup END
