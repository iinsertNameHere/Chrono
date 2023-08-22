import "../utility/logger"
import "datatypes"

import std/streams
import strutils

#########################################################################
## Instructions
#########################################################################
type InstructionType* = enum
    ## All nemo instruction
    INST_NOP = 0,

    # Stack Operations
    INST_PUSH,
    INST_DUP,
    INST_SWAP,
    INST_DEL,

    # Math Operations
    INST_ADD,
    INST_SUB,
    INST_MUL,
    INST_DIV,
    INST_MOD,

    # String Operations
    INST_STR,

    # Bit Operations
    INST_BAND,
    INST_BOR,
    INST_XOR,
    INST_SHL,
    INST_SHR,

    # Positional Operations
    INST_JUMP,
    INST_JUMPC,
    INST_CALL,
    INST_CALLC,
    INST_RETURN,
    INST_CLOCK,
    INST_HALT,

    # Logical Operations
    INST_AND,
    INST_OR,
    INST_NOT,
    INST_EQUAL,
    INST_GREATER,
    INST_LESS,

    # Output Operations
    INST_OUTPUT,
    INST_DUMP,

    # Error Operation
    INST_ERROR

# Constant that holds all Instructions that take no operand
const NoOperandInsts* = @[INST_NOP, INST_RETURN, INST_HALT, INST_CLOCK]

type Instruction* = object
    ## Nemo Instruction
    ## typ: Hold The type of the instruction (InstructionType)
    ## operand: Holds an "argument" of Type Word that can be interpreted as numb (int), float, bool, char and byte.
    typ*: InstructionType
    operand*: Word

proc NewInst*(instType: InstructionType, operand: Word): Instruction =
    ## Inits a new Instruction
    result.typ = instType
    result.operand = operand

proc takesOperand*(inst: Instruction): bool =
    ## Returns True if the Inst takes an operand
    result = if inst.typ in NoOperandInsts: false else: true

proc takesOperand*(instType: InstructionType): bool =
    ## Returns True if the Inst takes an operand
    result = if instType in NoOperandInsts: false else: true

proc InstName*(inst: Instruction): string =
    ## Gets the name of an instruction.
    result = $repr(inst.typ).split('_')[1]

proc InstName*(instType: InstructionType): string =
    ## Gets the name of an instruction based on an InstructionType.
    result = $repr(instType).split('_')[1]

proc GetInstTypeByName*(name: string): InstructionType =
    ## Check if name is a valid instruction
    ## If name is VALID:
    ##     Return INST_TYPE of name
    ## Else:
    ##     Return INST_ERROR

    # Loop TnstructionTypes and check if name in them
    for inst in InstructionType:
        var strrepr = $repr(inst).split('_')[1]
        if name.toUpper() == strrepr:
            # Return InstType if name in InstTypes
            return inst

    # Return INST_ERROR if name not in InstTypes
    return INST_ERROR

#########################################################################
## Labels
#########################################################################
type Label* = object
    ## Label object that hold the name and location of the label in the program (used in execution)
    name*: string
    address*: uint
    line*: uint
    file*: string

proc NewLabel*(name: string, address: uint, line: uint, file: string): Label =
    result.name = name
    result.address = address
    result.line = line
    result.file = file

#########################################################################
## Macros
#########################################################################
type Macro* = object
    name*: string
    body*: seq[Instruction]
    line*: uint
    file*: string

proc NewMacro*(name: string, body: seq[Instruction], line: uint, file: string): Macro =
    result.name = name
    result.body = body
    result.line = line
    result.file = file

#########################################################################
## Bytecode
#########################################################################
type Program* = seq[Instruction]

type Bytecode* = object
    ## Object that holds a Program and all Registerd labeld (not used in execution)
    code*: Program
    labels*: seq[Label]
    macros*: seq[Macro]
    includes*: seq[string]

proc add*(bc1: var Bytecode, bc2: Bytecode) =
    bc1.code &= bc2.code
    bc1.labels &= bc2.labels
    bc1.includes &= bc2.includes

proc RegisterLabel*(bytecode: var Bytecode, name: string, address: uint) =
    ## Registers a new label in the Bytecode

    # Creating a new Label and setting name and address
    var newLabel: Label
    newLabel.name = name
    newLabel.address = address
    newLabel.line = CurrentFilePosition.currentLine
    newLabel.file = CurrentFilePosition.currentFile

    # Checking that label dose not already exists
    for l in bytecode.labels:
        if l.name == newLabel.name:
            LogError(" Label \"$#\" is already registerd at line $# in file \"$#\"!" % [l.name, $l.line, l.file], true)
            quit(-1)
    
    for m in bytecode.macros:
        if m.name == newLabel.name:
            LogError("\"$#\" is already used as a Macro name at line $# in file \"$#\"" % [m.name, $m.line, m.file], true)
            quit(-1)

    # Adding label
    bytecode.labels.add(newLabel)

proc hasLabel*(bytecode: var Bytecode, labelName: string): int =
    result = -1
    for label in bytecode.labels:
        if label.name == labelName:
            result = int(label.address)
            break

proc RegisterMacro*(bytecode: var Bytecode, name: string, body: seq[Instruction]) =
    ## Registers a new Macro

    # Creating a new Macro and setting name and address
    var newMacro: Macro
    newMacro.name = name
    newMacro.body = body
    newMacro.line = CurrentFilePosition.currentLine
    newMacro.file = CurrentFilePosition.currentFile

    # Checking that label dose not already exists
    for l in bytecode.labels:
        if l.name == newMacro.name:
            LogError(" Label \"$#\" is already registerd at line $# in file \"$#\"!" % [l.name, $l.line, l.file], true)
            quit(-1)
    
    for m in bytecode.macros:
        if m.name == newMacro.name:
            LogError("\"$#\" is already used as a Macro name at line $# in file \"$#\"" % [m.name, $m.line, m.file], true)
            quit(-1)

    # Adding label
    bytecode.macros.add(newMacro)

type MetaData = object
    ## Object to store file metatada like version, magic and programLength
    version: uint16
    magic: uint32
    programLength: uint64

# Constants that hold the programs current File Version and Magic Number
const version: uint16 = 1
const magic: uint32 = 0xEDF5877

proc WriteToFile*(bytecode: Bytecode, path: string) =
    ## Writes a Bytecode object to file
    
    # Creating file MetaData and setting version, magic and programLength
    var meta: MetaData
    meta.version = version
    meta.magic = magic
    meta.programLength = uint64(bytecode.code.len)

    # Creating new File Stream
    var fstrm = newFileStream(path, fmWrite)
    if isNil(fstrm):
        LogError("Could not open File Stream to file: '$#'!" % (path))
        quit(-1)
    
    # Writing MetaData
    fstrm.write(meta)

    # Writing Instructions
    for inst in bytecode.code:
        fstrm.write(inst)

    fstrm.close()

proc LoadProgramFromFile*(path: string): Program =
    ## Loads a Program object from file
    ## Returns: Loaded Program

    var meta: MetaData

    # Creating new File Stream
    var fstrm = newFileStream(path, fmRead)
    if isNil(fstrm):
        LogError("Could not open File Stream to file: '$#'!" % (path))
        quit(-1)
    
    # Validating file MetaData
    discard fstrm.readData(meta.addr, sizeof(meta))
    if meta.version < version:
        LogError("Outdated file Version!")
        quit(-1)
    elif meta.version > version:
        LogError("Unknown file Version!")
        quit(-1)
    elif meta.programLength < 1:
        LogError("Invalid Program Length!")
        quit(-1)

    # Reading in Instructions
    for i in countup(1, int(meta.programLength)):
        var inst: Instruction
        discard fstrm.readData(inst.addr, sizeof(inst))
        # Adding Instruction to Programm
        result.add(inst)

    fstrm.close()
    
proc parseWord*(str: string, labels: seq[Label]): Word =
    ## Parses a Word value contained in `str`

    # Getting DataType
    var dtype: DataType = DetectDataType(str)
    try:
        var s = str
        case dtype:
            of Numb: 
                if str.startsWith("0x"):
                    # Parsing hexstring to numb
                    result = NewWord(parseHexInt(s))
                else:
                    # Parsing str to numb
                    s.removeSuffix('i')
                    result = NewWord(parseInt(s))
            of Float:
                # Parsing str to float
                s.removeSuffix('f')
                result = NewWord(parseFloat(s))
            of Bool:
                # Parsing str to bool
                var v = (if str == "true": true else: false)
                result = NewWord(v)
            of Char:
                # Parsing str to char
                s.removePrefix('\'')
                s.removeSuffix('\'')
                result = NewWord(char(s[0]))
            of EscapedChar:
                # Parsing str to Escaped Char
                s.removePrefix('\'')
                s.removeSuffix('\'')
                result = NewWord(parseEscapedChar(s))
            of NullType:
                # Checking if str is a label
                var found = false
                for l in labels:
                    if l.name == s:
                        result = NewWord(int(l.address))
                        found = true
                        break
                # Checking if str is a FromStackWord and should be taken from the first stack possition as Runtime
                if s == "$":
                    result = NewFromStackWord()

                elif not found:
                    LogError("DataType of '$#' is unknown!" % (s), true)
                    quit(-1)
                
    except Exception as e:
        if e.name == "RangeDefect":
            # If value to big: ERROR
            LogError("'$#' value out of range!" % (str), true)
            quit(-1)