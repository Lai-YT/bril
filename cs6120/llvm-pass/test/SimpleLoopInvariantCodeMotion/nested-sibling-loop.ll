; RUN: %opt -S --load-pass-plugin=%slicm_build_dir/SimpleLoopInvariantCodeMotionPass.so -passes='loop-simplify,slicm' %s -o - | FileCheck %s

; RUN: %opt -S --load-pass-plugin=%slicm_build_dir/SimpleLoopInvariantCodeMotionPass.so -passes='loop-simplify,slicm' -pass-remarks=slicm -pass-remarks-analysis=slicm -pass-remarks-missed=slicm --disable-output %s 2>&1 | FileCheck %s --check-prefix=REMARKS
; REMARKS: remark: nested-sibling-loop.c:30:15: [main]: Instruction has been hoisted
; REMARKS: remark: nested-sibling-loop.c:30:17: [main]: Instruction has been hoisted
; REMARKS: remark: nested-sibling-loop.c:32:17: [main]: Instruction has been hoisted
; REMARKS: remark: nested-sibling-loop.c:34:5: [main]: Instruction is unsafe to hoist
; REMARKS: remark: nested-sibling-loop.c:28:5: [main]: Instruction is unsafe to hoist
; REMARKS: remark: nested-sibling-loop.c:15:15: [main]: Instruction has been hoisted
; REMARKS: remark: nested-sibling-loop.c:15:17: [main]: Instruction has been hoisted
; REMARKS: remark: nested-sibling-loop.c:17:17: [main]: Instruction has been hoisted
; REMARKS: remark: nested-sibling-loop.c:19:5: [main]: Instruction is unsafe to hoist
; REMARKS: remark: nested-sibling-loop.c:13:5: [main]: Instruction is unsafe to hoist
; REMARKS: remark: nested-sibling-loop.c:15:15: [main]: Instruction has been hoisted
; REMARKS: remark: nested-sibling-loop.c:15:17: [main]: Instruction has been hoisted
; REMARKS: remark: nested-sibling-loop.c:13:10: [main]: Instruction is unsafe to hoist
; REMARKS: remark: nested-sibling-loop.c:30:15: [main]: Instruction has been hoisted
; REMARKS: remark: nested-sibling-loop.c:30:17: [main]: Instruction has been hoisted
; REMARKS: remark: nested-sibling-loop.c:28:10: [main]: Instruction is unsafe to hoist
; REMARKS: remark: nested-sibling-loop.c:37:3: [main]: Instruction is unsafe to hoist
; REMARKS: remark: nested-sibling-loop.c:7:3: [main]: Instruction is unsafe to hoist

source_filename = "nested-sibling-loop.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@x = dso_local global i32 1, align 4, !dbg !0
@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1, !dbg !5

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !20 {
; The entry block is the preheader for the outer loop.
; CHECK: entry:
; CHECK: %0 = load i32, ptr @x, align 4
; CHECK: %add = add nsw i32 %0, 5
; CHECK: %1 = load i32, ptr @x, align 4
; CHECK: %add13 = add nsw i32 %1, 6
; CHECK: br label %for.cond
entry:
  call void @llvm.dbg.value(metadata i32 0, metadata !24, metadata !DIExpression()), !dbg !25
  call void @llvm.dbg.value(metadata i32 0, metadata !26, metadata !DIExpression()), !dbg !28
  br label %for.cond, !dbg !29

for.cond:                                         ; preds = %for.inc22, %entry
  %j.0 = phi i32 [ 0, %entry ], [ %inc23, %for.inc22 ], !dbg !30
  %g_sum.0 = phi i32 [ 0, %entry ], [ %add21, %for.inc22 ], !dbg !25
  call void @llvm.dbg.value(metadata i32 %g_sum.0, metadata !24, metadata !DIExpression()), !dbg !25
  call void @llvm.dbg.value(metadata i32 %j.0, metadata !26, metadata !DIExpression()), !dbg !28
  %cmp = icmp slt i32 %j.0, 10, !dbg !31
  br i1 %cmp, label %for.body, label %for.end24, !dbg !33

; CHECK: for.body:
; CHECK: %add4 = add nsw i32 %add, %j.0
; CHECK: br label %for.cond1
for.body:                                         ; preds = %for.cond
  call void @llvm.dbg.value(metadata i32 0, metadata !34, metadata !DIExpression()), !dbg !36
  call void @llvm.dbg.value(metadata i32 %j.0, metadata !37, metadata !DIExpression()), !dbg !36
  call void @llvm.dbg.value(metadata i32 0, metadata !38, metadata !DIExpression()), !dbg !40
  br label %for.cond1, !dbg !41

for.cond1:                                        ; preds = %for.inc, %for.body
  %i.0 = phi i32 [ 0, %for.body ], [ %inc, %for.inc ], !dbg !42
  %sum_1.0 = phi i32 [ 0, %for.body ], [ %add5, %for.inc ], !dbg !36
  call void @llvm.dbg.value(metadata i32 %sum_1.0, metadata !34, metadata !DIExpression()), !dbg !36
  call void @llvm.dbg.value(metadata i32 %i.0, metadata !38, metadata !DIExpression()), !dbg !40
  %cmp2 = icmp slt i32 %i.0, 10, !dbg !43
  br i1 %cmp2, label %for.body3, label %for.end, !dbg !45

; CHECK: for.body3:
; CHECK-NOT: %0 = load i32, ptr @x, align 4, !dbg !46; CHECK-NOT: %add = add nsw i32 %0, 5, !dbg !48
; CHECK-NOT: %add4 = add nsw i32 %add, %j.0, !dbg !51
; CHECK: %add5 = add nsw i32 %sum_1.0, %add4
; CHECK: br label %for.inc
for.body3:                                        ; preds = %for.cond1
  %0 = load i32, ptr @x, align 4, !dbg !46
  %add = add nsw i32 %0, 5, !dbg !48
  call void @llvm.dbg.value(metadata i32 %add, metadata !49, metadata !DIExpression()), !dbg !50
  %add4 = add nsw i32 %add, %j.0, !dbg !51
  call void @llvm.dbg.value(metadata i32 %add4, metadata !52, metadata !DIExpression()), !dbg !50
  %add5 = add nsw i32 %sum_1.0, %add4, !dbg !53
  call void @llvm.dbg.value(metadata i32 %add5, metadata !34, metadata !DIExpression()), !dbg !36
  br label %for.inc, !dbg !54

for.inc:                                          ; preds = %for.body3
  %inc = add nsw i32 %i.0, 1, !dbg !55
  call void @llvm.dbg.value(metadata i32 %inc, metadata !38, metadata !DIExpression()), !dbg !40
  br label %for.cond1, !dbg !56, !llvm.loop !57

; The exit block of the first inner loop is the preheader for the second inner loop.
; CHECK: for.end:
; CHECK-NOT: %add6 = add nsw i32 %g_sum.0, %sum_1.0, !dbg !61
; CHECK-NOT: %add7 = add nsw i32 %j.0, 1, !dbg !63
; CHECK: %add15 = add nsw i32 %add13, %add7
; CHECK: br label %for.cond9
for.end:                                          ; preds = %for.cond1
  %call = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %sum_1.0), !dbg !60
  %add6 = add nsw i32 %g_sum.0, %sum_1.0, !dbg !61
  call void @llvm.dbg.value(metadata i32 %add6, metadata !24, metadata !DIExpression()), !dbg !25
  call void @llvm.dbg.value(metadata i32 0, metadata !62, metadata !DIExpression()), !dbg !36
  %add7 = add nsw i32 %j.0, 1, !dbg !63
  call void @llvm.dbg.value(metadata i32 %add7, metadata !64, metadata !DIExpression()), !dbg !36
  call void @llvm.dbg.value(metadata i32 0, metadata !65, metadata !DIExpression()), !dbg !67
  br label %for.cond9, !dbg !68

for.cond9:                                        ; preds = %for.inc17, %for.end
  %sum_2.0 = phi i32 [ 0, %for.end ], [ %add16, %for.inc17 ], !dbg !36
  %i8.0 = phi i32 [ 0, %for.end ], [ %inc18, %for.inc17 ], !dbg !69
  call void @llvm.dbg.value(metadata i32 %i8.0, metadata !65, metadata !DIExpression()), !dbg !67
  call void @llvm.dbg.value(metadata i32 %sum_2.0, metadata !62, metadata !DIExpression()), !dbg !36
  %cmp10 = icmp slt i32 %i8.0, 20, !dbg !70
  br i1 %cmp10, label %for.body11, label %for.end19, !dbg !72

; CHECK: for.body11:
; CHECK-NOT: %1 = load i32, ptr @x, align 4, !dbg !73
; CHECK-NOT: %add13 = add nsw i32 %1, 6, !dbg !75
; CHECK-NOT: %add15 = add nsw i32 %add13, %add7, !dbg !78
; CHECK: %add16 = add nsw i32 %sum_2.0, %add15
; CHECK: br label %for.inc17
for.body11:                                       ; preds = %for.cond9
  %1 = load i32, ptr @x, align 4, !dbg !73
  %add13 = add nsw i32 %1, 6, !dbg !75
  call void @llvm.dbg.value(metadata i32 %add13, metadata !76, metadata !DIExpression()), !dbg !77
  %add15 = add nsw i32 %add13, %add7, !dbg !78
  call void @llvm.dbg.value(metadata i32 %add15, metadata !79, metadata !DIExpression()), !dbg !77
  %add16 = add nsw i32 %sum_2.0, %add15, !dbg !80
  call void @llvm.dbg.value(metadata i32 %add16, metadata !62, metadata !DIExpression()), !dbg !36
  br label %for.inc17, !dbg !81

for.inc17:                                        ; preds = %for.body11
  %inc18 = add nsw i32 %i8.0, 1, !dbg !82
  call void @llvm.dbg.value(metadata i32 %inc18, metadata !65, metadata !DIExpression()), !dbg !67
  br label %for.cond9, !dbg !83, !llvm.loop !84

for.end19:                                        ; preds = %for.cond9
  %call20 = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %sum_2.0), !dbg !86
  %add21 = add nsw i32 %add6, %sum_2.0, !dbg !87
  call void @llvm.dbg.value(metadata i32 %add21, metadata !24, metadata !DIExpression()), !dbg !25
  br label %for.inc22, !dbg !88

for.inc22:                                        ; preds = %for.end19
  %inc23 = add nsw i32 %j.0, 1, !dbg !89
  call void @llvm.dbg.value(metadata i32 %inc23, metadata !26, metadata !DIExpression()), !dbg !28
  br label %for.cond, !dbg !90, !llvm.loop !91

for.end24:                                        ; preds = %for.cond
  %call25 = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %g_sum.0), !dbg !93
  ret i32 0, !dbg !94
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

declare i32 @printf(ptr noundef, ...) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.value(metadata, metadata, metadata) #1

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!12, !13, !14, !15, !16, !17, !18}
!llvm.ident = !{!19}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "x", scope: !2, file: !3, line: 3, type: !11, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C11, file: !3, producer: "Ubuntu clang version 17.0.6 (++20231209124227+6009708b4367-1~exp1~20231209124336.77)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, globals: !4, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "nested-sibling-loop.c", directory: "")
!4 = !{!0, !5}
!5 = !DIGlobalVariableExpression(var: !6, expr: !DIExpression())
!6 = distinct !DIGlobalVariable(scope: null, file: !3, line: 20, type: !7, isLocal: true, isDefinition: true)
!7 = !DICompositeType(tag: DW_TAG_array_type, baseType: !8, size: 32, elements: !9)
!8 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!9 = !{!10}
!10 = !DISubrange(count: 4)
!11 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!12 = !{i32 7, !"Dwarf Version", i32 5}
!13 = !{i32 2, !"Debug Info Version", i32 3}
!14 = !{i32 1, !"wchar_size", i32 4}
!15 = !{i32 8, !"PIC Level", i32 2}
!16 = !{i32 7, !"PIE Level", i32 2}
!17 = !{i32 7, !"uwtable", i32 2}
!18 = !{i32 7, !"frame-pointer", i32 2}
!19 = !{!"Ubuntu clang version 17.0.6 (++20231209124227+6009708b4367-1~exp1~20231209124336.77)"}
!20 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 5, type: !21, scopeLine: 5, spFlags: DISPFlagDefinition, unit: !2, retainedNodes: !23)
!21 = !DISubroutineType(types: !22)
!22 = !{!11}
!23 = !{}
!24 = !DILocalVariable(name: "g_sum", scope: !20, file: !3, line: 6, type: !11)
!25 = !DILocation(line: 0, scope: !20)
!26 = !DILocalVariable(name: "j", scope: !27, file: !3, line: 7, type: !11)
!27 = distinct !DILexicalBlock(scope: !20, file: !3, line: 7, column: 3)
!28 = !DILocation(line: 0, scope: !27)
!29 = !DILocation(line: 7, column: 8, scope: !27)
!30 = !DILocation(line: 7, scope: !27)
!31 = !DILocation(line: 7, column: 21, scope: !32)
!32 = distinct !DILexicalBlock(scope: !27, file: !3, line: 7, column: 3)
!33 = !DILocation(line: 7, column: 3, scope: !27)
!34 = !DILocalVariable(name: "sum_1", scope: !35, file: !3, line: 11, type: !11)
!35 = distinct !DILexicalBlock(scope: !32, file: !3, line: 7, column: 32)
!36 = !DILocation(line: 0, scope: !35)
!37 = !DILocalVariable(name: "y", scope: !35, file: !3, line: 12, type: !11)
!38 = !DILocalVariable(name: "i", scope: !39, file: !3, line: 13, type: !11)
!39 = distinct !DILexicalBlock(scope: !35, file: !3, line: 13, column: 5)
!40 = !DILocation(line: 0, scope: !39)
!41 = !DILocation(line: 13, column: 10, scope: !39)
!42 = !DILocation(line: 13, scope: !39)
!43 = !DILocation(line: 13, column: 23, scope: !44)
!44 = distinct !DILexicalBlock(scope: !39, file: !3, line: 13, column: 5)
!45 = !DILocation(line: 13, column: 5, scope: !39)
!46 = !DILocation(line: 15, column: 15, scope: !47)
!47 = distinct !DILexicalBlock(scope: !44, file: !3, line: 13, column: 34)
!48 = !DILocation(line: 15, column: 17, scope: !47)
!49 = !DILocalVariable(name: "s", scope: !47, file: !3, line: 15, type: !11)
!50 = !DILocation(line: 0, scope: !47)
!51 = !DILocation(line: 17, column: 17, scope: !47)
!52 = !DILocalVariable(name: "t", scope: !47, file: !3, line: 17, type: !11)
!53 = !DILocation(line: 18, column: 13, scope: !47)
!54 = !DILocation(line: 19, column: 5, scope: !47)
!55 = !DILocation(line: 13, column: 30, scope: !44)
!56 = !DILocation(line: 13, column: 5, scope: !44)
!57 = distinct !{!57, !45, !58, !59}
!58 = !DILocation(line: 19, column: 5, scope: !39)
!59 = !{!"llvm.loop.mustprogress"}
!60 = !DILocation(line: 20, column: 5, scope: !35)
!61 = !DILocation(line: 21, column: 11, scope: !35)
!62 = !DILocalVariable(name: "sum_2", scope: !35, file: !3, line: 26, type: !11)
!63 = !DILocation(line: 27, column: 15, scope: !35)
!64 = !DILocalVariable(name: "z", scope: !35, file: !3, line: 27, type: !11)
!65 = !DILocalVariable(name: "i", scope: !66, file: !3, line: 28, type: !11)
!66 = distinct !DILexicalBlock(scope: !35, file: !3, line: 28, column: 5)
!67 = !DILocation(line: 0, scope: !66)
!68 = !DILocation(line: 28, column: 10, scope: !66)
!69 = !DILocation(line: 28, scope: !66)
!70 = !DILocation(line: 28, column: 23, scope: !71)
!71 = distinct !DILexicalBlock(scope: !66, file: !3, line: 28, column: 5)
!72 = !DILocation(line: 28, column: 5, scope: !66)
!73 = !DILocation(line: 30, column: 15, scope: !74)
!74 = distinct !DILexicalBlock(scope: !71, file: !3, line: 28, column: 34)
!75 = !DILocation(line: 30, column: 17, scope: !74)
!76 = !DILocalVariable(name: "s", scope: !74, file: !3, line: 30, type: !11)
!77 = !DILocation(line: 0, scope: !74)
!78 = !DILocation(line: 32, column: 17, scope: !74)
!79 = !DILocalVariable(name: "t", scope: !74, file: !3, line: 32, type: !11)
!80 = !DILocation(line: 33, column: 13, scope: !74)
!81 = !DILocation(line: 34, column: 5, scope: !74)
!82 = !DILocation(line: 28, column: 30, scope: !71)
!83 = !DILocation(line: 28, column: 5, scope: !71)
!84 = distinct !{!84, !72, !85, !59}
!85 = !DILocation(line: 34, column: 5, scope: !66)
!86 = !DILocation(line: 35, column: 5, scope: !35)
!87 = !DILocation(line: 36, column: 11, scope: !35)
!88 = !DILocation(line: 37, column: 3, scope: !35)
!89 = !DILocation(line: 7, column: 28, scope: !32)
!90 = !DILocation(line: 7, column: 3, scope: !32)
!91 = distinct !{!91, !33, !92, !59}
!92 = !DILocation(line: 37, column: 3, scope: !27)
!93 = !DILocation(line: 38, column: 3, scope: !20)
!94 = !DILocation(line: 40, column: 3, scope: !20)
