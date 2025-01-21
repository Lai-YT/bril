; RUN: %opt -S --load-pass-plugin=%slicm_build_dir/SimpleLoopInvariantCodeMotionPass.so -passes='loop-simplify,slicm' %s -o - | FileCheck %s

; RUN: %opt -S --load-pass-plugin=%slicm_build_dir/SimpleLoopInvariantCodeMotionPass.so -passes='loop-simplify,slicm' -pass-remarks=slicm -pass-remarks-analysis=slicm -pass-remarks-missed=slicm --disable-output %s 2>&1 | FileCheck %s --check-prefix=REMARKS
; REMARKS: remark: loop.c:9:13: [main]: Instruction has been hoisted
; REMARKS: remark: loop.c:9:15: [main]: Instruction has been hoisted
; REMARKS: remark: loop.c:11:3: [main]: Instruction is unsafe to hoist
; REMARKS: remark: loop.c:7:3: [main]: Instruction is unsafe to hoist

source_filename = "loop.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@x = dso_local global i32 1, align 4, !dbg !0
@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1, !dbg !5

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !20 {
; The entry block is the preheader, where the hoisted load instructions are placed.
; CHECK: entry:
; CHECK: %0 = load i32, ptr @x, align 4
; CHECK: %add = add nsw i32 %0, 5
; CHECK: br label %for.cond
entry:
  call void @llvm.dbg.value(metadata i32 0, metadata !24, metadata !DIExpression()), !dbg !25
  call void @llvm.dbg.value(metadata i32 0, metadata !26, metadata !DIExpression()), !dbg !28
  br label %for.cond, !dbg !29

for.cond:                                         ; preds = %for.inc, %entry
  %sum.0 = phi i32 [ 0, %entry ], [ %add1, %for.inc ], !dbg !25
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !30
  call void @llvm.dbg.value(metadata i32 %i.0, metadata !26, metadata !DIExpression()), !dbg !28
  call void @llvm.dbg.value(metadata i32 %sum.0, metadata !24, metadata !DIExpression()), !dbg !25
  %cmp = icmp slt i32 %i.0, 10, !dbg !31
  br i1 %cmp, label %for.body, label %for.end, !dbg !33

; CHECK: for.body:
; CHECK-NOT: %0 = load i32, ptr @x, align 4
; CHECK-NOT: %add = add nsw i32 %0, 5
; CHECK: %add1 = add nsw i32 %sum.0, %add
for.body:                                         ; preds = %for.cond
  %0 = load i32, ptr @x, align 4, !dbg !34
  %add = add nsw i32 %0, 5, !dbg !36
  call void @llvm.dbg.value(metadata i32 %add, metadata !37, metadata !DIExpression()), !dbg !38
  %add1 = add nsw i32 %sum.0, %add, !dbg !39
  call void @llvm.dbg.value(metadata i32 %add1, metadata !24, metadata !DIExpression()), !dbg !25
  br label %for.inc, !dbg !40

for.inc:                                          ; preds = %for.body
  %inc = add nsw i32 %i.0, 1, !dbg !41
  call void @llvm.dbg.value(metadata i32 %inc, metadata !26, metadata !DIExpression()), !dbg !28
  br label %for.cond, !dbg !42, !llvm.loop !43

for.end:                                          ; preds = %for.cond
  %call = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %sum.0), !dbg !46
  ret i32 0, !dbg !47
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
!3 = !DIFile(filename: "loop.c", directory: "")
!4 = !{!0, !5}
!5 = !DIGlobalVariableExpression(var: !6, expr: !DIExpression())
!6 = distinct !DIGlobalVariable(scope: null, file: !3, line: 12, type: !7, isLocal: true, isDefinition: true)
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
!24 = !DILocalVariable(name: "sum", scope: !20, file: !3, line: 6, type: !11)
!25 = !DILocation(line: 0, scope: !20)
!26 = !DILocalVariable(name: "i", scope: !27, file: !3, line: 7, type: !11)
!27 = distinct !DILexicalBlock(scope: !20, file: !3, line: 7, column: 3)
!28 = !DILocation(line: 0, scope: !27)
!29 = !DILocation(line: 7, column: 8, scope: !27)
!30 = !DILocation(line: 7, scope: !27)
!31 = !DILocation(line: 7, column: 21, scope: !32)
!32 = distinct !DILexicalBlock(scope: !27, file: !3, line: 7, column: 3)
!33 = !DILocation(line: 7, column: 3, scope: !27)
!34 = !DILocation(line: 9, column: 13, scope: !35)
!35 = distinct !DILexicalBlock(scope: !32, file: !3, line: 7, column: 32)
!36 = !DILocation(line: 9, column: 15, scope: !35)
!37 = !DILocalVariable(name: "s", scope: !35, file: !3, line: 9, type: !11)
!38 = !DILocation(line: 0, scope: !35)
!39 = !DILocation(line: 10, column: 9, scope: !35)
!40 = !DILocation(line: 11, column: 3, scope: !35)
!41 = !DILocation(line: 7, column: 28, scope: !32)
!42 = !DILocation(line: 7, column: 3, scope: !32)
!43 = distinct !{!43, !33, !44, !45}
!44 = !DILocation(line: 11, column: 3, scope: !27)
!45 = !{!"llvm.loop.mustprogress"}
!46 = !DILocation(line: 12, column: 3, scope: !20)
!47 = !DILocation(line: 13, column: 3, scope: !20)
