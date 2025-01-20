; RUN: %opt -S --load-pass-plugin=%slicm_build_dir/SimpleLoopInvariantCodeMotionPass.so -passes='loop-simplify,slicm' %s -o - | FileCheck %s

source_filename = "nested-loop.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@x = dso_local global i32 1, align 4
@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 {
; The entry block is the preheader for the outer loop.
; CHECK: entry:
; CHECK-NEXT: %0 = load i32, ptr @x, align 4
; CHECK-NEXT: %add = add nsw i32 %0, 5
; CHECK-NEXT: br label %for.cond
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc7, %entry
  %j.0 = phi i32 [ 0, %entry ], [ %inc8, %for.inc7 ]
  %g_sum.0 = phi i32 [ 0, %entry ], [ %add6, %for.inc7 ]
  %cmp = icmp slt i32 %j.0, 10
  br i1 %cmp, label %for.body, label %for.end9

; This is the preheader for the inner loop.
; CHECK: for.body:
; CHECK-NEXT: %add4 = add nsw i32 %add, %j.0
; CHECK-NEXT: br label %for.cond1
for.body:                                         ; preds = %for.cond
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc, %for.body
  %sum.0 = phi i32 [ 0, %for.body ], [ %add5, %for.inc ]
  %i.0 = phi i32 [ 0, %for.body ], [ %inc, %for.inc ]
  %cmp2 = icmp slt i32 %i.0, 10
  br i1 %cmp2, label %for.body3, label %for.end

; CHECK: for.body3:
; CHECK-NEXT: %add5 = add nsw i32 %sum.0, %add4
; CHECK-NEXT: br label %for.inc
for.body3:                                        ; preds = %for.cond1
  %0 = load i32, ptr @x, align 4
  %add = add nsw i32 %0, 5
  %add4 = add nsw i32 %add, %j.0
  %add5 = add nsw i32 %sum.0, %add4
  br label %for.inc

for.inc:                                          ; preds = %for.body3
  %inc = add nsw i32 %i.0, 1
  br label %for.cond1, !llvm.loop !6

for.end:                                          ; preds = %for.cond1
  %add6 = add nsw i32 %g_sum.0, %sum.0
  %call = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %sum.0)
  br label %for.inc7

for.inc7:                                         ; preds = %for.end
  %inc8 = add nsw i32 %j.0, 1
  br label %for.cond, !llvm.loop !8

for.end9:                                         ; preds = %for.cond
  %call10 = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %g_sum.0)
  ret i32 0
}

declare i32 @printf(ptr noundef, ...) #1

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 17.0.6 (++20231209124227+6009708b4367-1~exp1~20231209124336.77)"}
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}
!8 = distinct !{!8, !7}
