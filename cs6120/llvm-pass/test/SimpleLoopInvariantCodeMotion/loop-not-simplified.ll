; Not running loop pass on this file so it is not in simplified form.
; RUN: %opt --load-pass-plugin=%slicm_build_dir/SimpleLoopInvariantCodeMotionPass.so --passes='mem2reg,slicm' -pass-remarks-analysis=slicm -disable-output < %s 2>&1 | FileCheck --check-prefix=REMARKS %s

; REMARKS: remark: loop-not-simplified.c:5:3: [main]: Loop is not a candidate for SLICM: Loop not in simplified form

source_filename = "loop-not-simplified.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1, !dbg !0

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !17 {
entry:
  %retval = alloca i32, align 4
  %i = alloca i32, align 4
  store i32 0, ptr %retval, align 4
  call void @llvm.dbg.declare(metadata ptr %i, metadata !22, metadata !DIExpression()), !dbg !23
  store i32 10, ptr %i, align 4, !dbg !23
  br label %while.cond, !dbg !24

while.cond:                                       ; preds = %if.end, %entry
  %0 = load i32, ptr %i, align 4, !dbg !25
  %dec = add nsw i32 %0, -1, !dbg !25
  store i32 %dec, ptr %i, align 4, !dbg !25
  %tobool = icmp ne i32 %0, 0, !dbg !24
  br i1 %tobool, label %while.body, label %while.end, !dbg !24

while.body:                                       ; preds = %while.cond
  %1 = load i32, ptr %i, align 4, !dbg !26
  %call = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %1), !dbg !28
  %2 = load i32, ptr %i, align 4, !dbg !29
  %cmp = icmp eq i32 %2, 5, !dbg !31
  br i1 %cmp, label %if.then, label %if.end, !dbg !32

if.then:                                          ; preds = %while.body
  br label %while.end, !dbg !33

if.end:                                           ; preds = %while.body
  br label %while.cond, !dbg !24, !llvm.loop !35

while.end:                                        ; preds = %if.then, %while.cond
  ret i32 0, !dbg !38
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

declare i32 @printf(ptr noundef, ...) #2

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!7}
!llvm.module.flags = !{!9, !10, !11, !12, !13, !14, !15}
!llvm.ident = !{!16}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 6, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "loop-not-simplified.c", directory: "")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 32, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 4)
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !2, producer: "Ubuntu clang version 17.0.6 (++20231209124227+6009708b4367-1~exp1~20231209124336.77)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, globals: !8, splitDebugInlining: false, nameTableKind: None)
!8 = !{!0}
!9 = !{i32 7, !"Dwarf Version", i32 5}
!10 = !{i32 2, !"Debug Info Version", i32 3}
!11 = !{i32 1, !"wchar_size", i32 4}
!12 = !{i32 8, !"PIC Level", i32 2}
!13 = !{i32 7, !"PIE Level", i32 2}
!14 = !{i32 7, !"uwtable", i32 2}
!15 = !{i32 7, !"frame-pointer", i32 2}
!16 = !{!"Ubuntu clang version 17.0.6 (++20231209124227+6009708b4367-1~exp1~20231209124336.77)"}
!17 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 3, type: !18, scopeLine: 3, spFlags: DISPFlagDefinition, unit: !7, retainedNodes: !21)
!18 = !DISubroutineType(types: !19)
!19 = !{!20}
!20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!21 = !{}
!22 = !DILocalVariable(name: "i", scope: !17, file: !2, line: 4, type: !20)
!23 = !DILocation(line: 4, column: 7, scope: !17)
!24 = !DILocation(line: 5, column: 3, scope: !17)
!25 = !DILocation(line: 5, column: 11, scope: !17)
!26 = !DILocation(line: 6, column: 20, scope: !27)
!27 = distinct !DILexicalBlock(scope: !17, file: !2, line: 5, column: 15)
!28 = !DILocation(line: 6, column: 5, scope: !27)
!29 = !DILocation(line: 7, column: 9, scope: !30)
!30 = distinct !DILexicalBlock(scope: !27, file: !2, line: 7, column: 9)
!31 = !DILocation(line: 7, column: 11, scope: !30)
!32 = !DILocation(line: 7, column: 9, scope: !27)
!33 = !DILocation(line: 9, column: 7, scope: !34)
!34 = distinct !DILexicalBlock(scope: !30, file: !2, line: 7, column: 17)
!35 = distinct !{!35, !24, !36, !37}
!36 = !DILocation(line: 11, column: 3, scope: !17)
!37 = !{!"llvm.loop.mustprogress"}
!38 = !DILocation(line: 12, column: 3, scope: !17)
