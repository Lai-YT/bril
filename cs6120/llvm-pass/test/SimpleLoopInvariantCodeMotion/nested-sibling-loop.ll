; RUN: %opt -S --load-pass-plugin=%slicm_build_dir/SimpleLoopInvariantCodeMotionPass.so -passes='loop-simplify,slicm' %s -o - | FileCheck %s

source_filename = "nested-sibling-loop.c"
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
; CHECK-NEXT: %1 = load i32, ptr @x, align 4
; CHECK-NEXT: %add13 = add nsw i32 %1, 6
; CHECK-NEXT: br label %for.cond
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc22, %entry
  %j.0 = phi i32 [ 0, %entry ], [ %inc23, %for.inc22 ]
  %g_sum.0 = phi i32 [ 0, %entry ], [ %add21, %for.inc22 ]
  %cmp = icmp slt i32 %j.0, 10
  br i1 %cmp, label %for.body, label %for.end24

; CHECK: for.body:
; CHECK-NEXT: %add4 = add nsw i32 %add, %j.0
; CHECK-NEXT: br label %for.cond1
for.body:                                         ; preds = %for.cond
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc, %for.body
  %i.0 = phi i32 [ 0, %for.body ], [ %inc, %for.inc ]
  %sum_1.0 = phi i32 [ 0, %for.body ], [ %add5, %for.inc ]
  %cmp2 = icmp slt i32 %i.0, 10
  br i1 %cmp2, label %for.body3, label %for.end

; CHECK: for.body3:
; CHECK-NEXT: %add5 = add nsw i32 %sum_1.0, %add4
; CHECK-NEXT: br label %for.inc
for.body3:                                        ; preds = %for.cond1
  %0 = load i32, ptr @x, align 4
  %add = add nsw i32 %0, 5
  %add4 = add nsw i32 %add, %j.0
  %add5 = add nsw i32 %sum_1.0, %add4
  br label %for.inc

for.inc:                                          ; preds = %for.body3
  %inc = add nsw i32 %i.0, 1
  br label %for.cond1, !llvm.loop !6

; The exit block of the first inner loop is the preheader for the second inner loop.
; CHECK: for.end:
; CHECK: %add15 = add nsw i32 %add13, %add7
; CHECK-NEXT: br label %for.cond9
for.end:                                          ; preds = %for.cond1
  %call = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %sum_1.0)
  %add6 = add nsw i32 %g_sum.0, %sum_1.0
  %add7 = add nsw i32 %j.0, 1
  br label %for.cond9

for.cond9:                                        ; preds = %for.inc17, %for.end
  %sum_2.0 = phi i32 [ 0, %for.end ], [ %add16, %for.inc17 ]
  %i8.0 = phi i32 [ 0, %for.end ], [ %inc18, %for.inc17 ]
  %cmp10 = icmp slt i32 %i8.0, 20
  br i1 %cmp10, label %for.body11, label %for.end19

; CHECK: for.body11:
; CHECK-NEXT: %add16 = add nsw i32 %sum_2.0, %add15
; CHECK-NEXT: br label %for.inc17
for.body11:                                       ; preds = %for.cond9
  %1 = load i32, ptr @x, align 4
  %add13 = add nsw i32 %1, 6
  %add15 = add nsw i32 %add13, %add7
  %add16 = add nsw i32 %sum_2.0, %add15
  br label %for.inc17

for.inc17:                                        ; preds = %for.body11
  %inc18 = add nsw i32 %i8.0, 1
  br label %for.cond9, !llvm.loop !8

for.end19:                                        ; preds = %for.cond9
  %call20 = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %sum_2.0)
  %add21 = add nsw i32 %add6, %sum_2.0
  br label %for.inc22

for.inc22:                                        ; preds = %for.end19
  %inc23 = add nsw i32 %j.0, 1
  br label %for.cond, !llvm.loop !9

for.end24:                                        ; preds = %for.cond
  %call25 = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %g_sum.0)
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
!9 = distinct !{!9, !7}
