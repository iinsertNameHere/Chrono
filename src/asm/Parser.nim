include "Bytecode.nim"
import std/streams

proc ParseLabels(prog: var Program, source: string) =
    prog.code = @[]
    prog.labels = @[]
    for l in splitLines(source):
        var line = l.strip()
        if line.len < 1:
            continue
        
        if line.startsWith('#'):
            continue

        var token = line.split(' ')

        if token.len < 1:
            continue
        
        var instType = GetInstTypeByName(token[0])

        if token.len > 1 and instType != INST_ERROR:
            prog.code.add(NewInst(INST_NOP, NewWord(0)))
            continue

        if token.len < 2 and token[0].endsWith(':'):
            var name = token[0]
            name.removeSuffix(':')
            prog.RegisterLabel(name, prog.code.len)
            LogDebug("Registerd Label '" & name & "' at addr " & $prog.code.len)
            prog.code.add(NewInst(INST_NOP, NewWord(0)))
            continue

        LogError("\"" & join(token, " ") & "\"" & " could not be Parsed!")

proc ParseCode(prog: var Program, source: string) =
    prog.code = @[]
    for l in splitLines(source):
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
            prog.code.add(NewInst(instType, NewWord(0)))
            continue
        
        if token.len < 2 and token[0].endsWith(':'):
            prog.code.add(NewInst(INST_NOP, NewWord(0)))
            continue

        if token.len > 1 and instType != INST_ERROR:
            var inst: Instruction

            case instType:
                of INST_NOP:
                    LogError("NOP dose not take a operand!")
                    quit(-1)
                of INST_RETURN:
                    LogError("RETURN dose not take a operand!")
                    quit(-1)
                of INST_HALT:
                    LogError("HALT dose not take a operand!")
                    quit(-1)
                else:
                    inst = NewInst(instType, parseWord(token[1], prog.labels))
            prog.code.add(inst)
            continue
            
        LogError("\"" & join(token, " ") & "\"" & " could not be Parsed!")

proc SourceToProgram(path: string): Program =
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
