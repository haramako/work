source_filename = "hoge.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
define i8 @main(i8 %a, i8 %b) {
  %1 = add i8 %a, %b
  ret i8 %1
}
