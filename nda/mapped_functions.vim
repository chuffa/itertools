" Clean after START  
normal /START

function! DoOnePattern(num)

 " Find the pattern -> "t register
 execute "normal! /PATTERN".a:num."

 " List into "d register
 execute "normal! /LIST".a:num."

 " for all element in the list, paste the "t at the end of the file and replace from there till the end X by i
 for i in split(@d)
  execute "normal! G\"tP:.,$s/X/".i."/g
 endfor  

endfunction


call DoOnePattern(1)
call DoOnePattern(2)
call DoOnePattern(3)

"Clang format
normal ==
