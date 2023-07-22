import "Bytecode"
import "../utility/Logger"
import "DataTypes"

import strutils
import std/streams

proc ParseLabels(prog: var Program, source: string) =
    prog.code = @[]
    prog.labels = @[]

    var lineNum = 0
    for l in splitLines(source):
        lineNum += 1
        var line = l.strip()
        if line.len < 1:
            continue
        
        if line.startsWith('#'):
            continue

        var token = line.split(' ')

        if token.len < 1:
            continue
        
        var instType = GetInstTypeByName(token[0])

        if token.len < 2 and instType != INST_ERROR:
            prog.code.add(NewInst(INST_NOP, NewWord(0)))
            continue

        if token.len > 1 and instType != INST_ERROR:
            prog.code.add(NewInst(INST_NOP, NewWord(0)))
            continue

        if token.len < 2 and token[0].endsWith(':'):
            var name = token[0]
            name.removeSuffix(':')
            prog.RegisterLabel(name, prog.code.len, lineNum)
            LogDebug("Registerd Label '" & name & "' with addr " & $prog.code.len)
            prog.code.add(NewInst(INST_NOP, NewWord(0)))
            continue

        LogError("At Line " & $lineNum & ":" & " \"" & join(token, " ") & "\" could not be Parsed!")
        quit(-1)

proc ParseCode(prog: var Program, source: string) =
    prog.code = @[]

    var lineNum = 0
    for l in splitLines(source):
        lineNum += 1
        var line = l.strip()
        if line.len < 1:
            continue

        if line.startsWith('#'):
            continue

        var token = line.split(' ')
        
        if token.len < 1:
            continue

        var instType = GetInstTypeByName(token[0])

        if token.len < 2 and instType != INST_ERROR:
            if not (instType in NoArgInsts):
                var instName = InstName(NewInst(instType, NewWord(0)))
                LogError("At Line " & $lineNum & ":" & "Instruction '" & instName & "' takes an argument!")
                quit(-1)
            prog.code.add(NewInst(instType, NewWord(0))) 
            continue
        
        if token.len < 2 and token[0].endsWith(':'):
            prog.code.add(NewInst(INST_NOP, NewWord(0)))
            continue

        if token.len > 1 and instType != INST_ERROR:
            var inst: Instruction
            if instType in NoArgInsts: 
                var instName = InstName(NewInst(instType, NewWord(0)))
                LogError("At Line " & $lineNum & ":" & "Instruction '" & instName & "' takes no argument!")
                quit(-1)
            inst = NewInst(instType, parseWord(token[1], prog.labels))
            prog.code.add(inst)
            continue
            
        LogError("At Line " & $lineNum & ":" & " \"" & join(token, " ") & "\" could not be Parsed!")
        quit(-1)

proc SourceToProgram*(path: string): Program =
    var fstrm = newFileStream(path, fmRead)
    var source = fstrm.readAll()

    if source.len < 1:
        LogError("Source file is Empty!")
        quit(-1)

    LogDebug("Parsing Labels...")
    result.ParseLabels(source)

    LogDebug("Parsing Code...")
    result.ParseCode(source)

    LogDebug("Parsing finished...")
