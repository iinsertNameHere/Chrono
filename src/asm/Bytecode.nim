import std/streams
import strutils
include "DataTypes.nim"

type InstructionType = enum
    INST_NOP = 0,

    INST_PUSH,
    INST_DUP,
    INST_SWAP,
    INST_DEL,

    INST_ADD,
    INST_MIN,
    INST_MUL,
    INST_DIV,
    INST_MOD,

    INST_AND,
    INST_OR,
    INST_XOR,
    INST_SHL,
    INST_SHR,

    INST_JUMP,
    INST_JUMPC,
    INST_CALL,
    INST_SYSCALL,
    INST_RETURN,
    INST_GOTO,

    INST_READ,
    INST_WRITE,

    INST_HALT,

    INST_ERROR

type Instruction = object
    instType: InstructionType
    operand: Word

proc InstName(inst: Instruction): string =
    result = $repr(inst.instType).split('_')[1]

proc NewInst(instType: InstructionType, operand: Word): Instruction =
    result.instType = instType
    result.operand = operand

proc GetInstTypeByName(name: string): InstructionType =
    for inst in InstructionType:
        var strrepr = $repr(inst).split('_')[1]
        if name.toUpper() == strrepr:
            return inst

    return INST_ERROR

type Label = object
    name: string
    address: int

type Program = object
    code: seq[Instruction]
    labels: seq[Label]

proc RegisterLabel(prog: var Program, name: string, address: int) =
    var newLabel: Label
    newLabel.name = name
    newLabel.address = address

    for l in prog.labels:
        if l.name == newLabel.name:
            LogError("Label '" & l.name & "' already defined at address " & $l.address)
            quit(-1)

    prog.labels.add(newLabel)

type MetaData = object
    version: uint16
    magic: uint32
    programLength: uint64

proc writeToFile(program: Program, path: string) =
    var meta: MetaData
    meta.version = 1
    meta.magic = 0xEDF5877
    meta.programLength = uint64(program.code.len)

    var fstrm = newFileStream(path, fmWrite)
    if isNil(fstrm):
        LogError("Could not write to file '" & path & "'!")
        quit(-1)
    
    fstrm.write(meta)
    for inst in program.code:
        fstrm.write(inst)

proc LoadFromFile(path: string): Program =
    var meta: MetaData

    var fstrm = newFileStream(path, fmRead)
    if isNil(fstrm):
        LogError("'" & path & "' not found!")
        quit(-1)
    
    discard fstrm.readData(meta.addr, sizeof(meta))

    for i in countup(1, int(meta.programLength)):
        var inst: Instruction
        discard fstrm.readData(inst.addr, sizeof(inst))
        result.code.add(inst)

proc parseWord(str: string, labels: seq[Label]): Word =
    var dtype: DataType = DetectDataType(str)
    try:
        var s = str
        case dtype:
            of Numb:
                if str.startsWith("0x"):
                        result = NewWord(parseHexInt(s))
                else:
                    s.removeSuffix('i')
                    result = NewWord(parseInt(s))
            of Float:
                s.removeSuffix('f')
                result = NewWord(parseFloat(s))
            of Bool:
                var v = (if str == "true": true else: false)
                result = NewWord(v)
            of Char:
                s.removePrefix('\'')
                s.removeSuffix('\'')
                result = NewWord(char(s[0]))
            of Byte:
                s.removeSuffix('b')
                result = NewWord(byte(parseInt(s)))
            of NullType:
                var found = false
                for l in labels:
                    if l.name == s:
                        result = NewWord(l.address)
                        found = true
                        break
                if not found:
                    LogError("DataType of '" & s & "' is unknown!")
                    quit(-1)
                
    except Exception as e:
        if e.name == "RangeDefect":
            LogError(str & " value out of range!\n")
            quit(-1)