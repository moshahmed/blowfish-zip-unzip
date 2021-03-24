function! MotpGetPass()
  if $fkey == ''
    :let $fkey=inputsecret("fkey:")
  endif
endfun

augroup FER
  au!

  " Decrypt buffer after reading
  au BufReadPost *.motp
    \ :call MotpGetPass()
    \|:setl viminfo= noswapfile noundofile nobackup
    \|:silent 1,$ !python motp.py --filedec - - $fkey

  " Encrypt buffer before writing
  au BufWritePre *.motp
    \ :call MotpGetPass()
    \|:setl viminfo= noswapfile noundofile nobackup
    \|:silent 1,$ !python motp.py --fileenc - - $fkey

augroup END
