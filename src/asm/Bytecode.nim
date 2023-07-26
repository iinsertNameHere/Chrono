import std/streams
import strutils
import "DataTypes"
import "../utility/Logger"

type InstructionType* = enum
    ## All croasm instruction
    INST_NOP = 0,

    INST_PUSH,
    INST_DUP,
    INST_SWAP,
    INST_DEL,

    INST_ADD,
    INST_SUB,
    INST_MUL,
    INST_DIV,
    INST_MOD,
    INST_STR,

    INST_BAND,
    INST_BOR,
    INST_XOR,
    INST_SHL,
    INST_SHR,

    INST_JUMP,
    INST_AND,
    INST_OR,
    INST_JUMPC,
    INST_CALL,
    INST_CALLC,
    INST_OUTPUT,
    INST_DUMP,
    INST_RETURN,
    INST_LEN,
    

    INST_EQUAL,
    INST_NOT,
    INST_GREATER,
    INST_LESS,

    INST_READ,
    INST_WRITE,

    INST_HALT,

    INST_ERROR

# Constant that holds all Instructions that take no operand
const NoOperandInsts* = @[INST_NOP, INST_RETURN, INST_HALT, INST_LEN]

type Instruction* = object
    ## Croasm Instruction
    ## instType: Hold The type of the instruction (InstructionType)
    ## operand: Holds an "argument" of Type Word that can be interpreted as numb (int), float, bool, char and byte.
    instType*: InstructionType
    operand*: Word

proc InstName*(inst: Instruction): string =
    ## Gets the name of an instruction.
    result = $repr(inst.instType).split('_')[1]

proc InstNameFromType*(instType: InstructionType): string =
    ## Gets the name of an instruction based on an InstructionType.
    result = $repr(instType).split('_')[1]

proc NewInst*(instType: InstructionType, operand: Word): Instruction =
    ## Inits a new Instruction
    result.instType = instType
    result.operand = operand

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

type Label* = object
    ## Label object that hold the name and location of the label in the program (used in execution)
    name: string
    address: int

type Program* = seq[Instruction]
## A list of Instructions

type Bytecode* = object
    ## Object that holds a Program and all Registerd labeld (not used in execution)
    code*: Program
    labels*: seq[Label]

proc RegisterLabel*(bytecode: var Bytecode, name: string, address: int, lineNum: int) =
    ## Registers a new label in the Bytecode

    # Creating a new Label and setting name and address
    var newLabel: Label
    newLabel.name = name
    newLabel.address = address

    # Checking that label dose not already exists
    for l in bytecode.labels:
        if l.name == newLabel.name:
            LogError("At Line " & $lineNum & ":" & " Label '" & l.name & "' is already defined!")
            quit(-1)

    # Adding label
    bytecode.labels.add(newLabel)

type MetaData = object
    ## Object to store file metatada like version, magic and programLength
    version: uint16
    magic: uint32
    programLength: uint64

# Constants that hold the programs current
# File Version and Magic Number
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
        LogError("Could not open File Stream to file: '" & path & "'!")
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
        LogError("Could not open File Stream to file: '" & path & "'!")
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

proc parseWord*(str: string, labels: seq[Label], lineNum: int): Word =
    ## Parses a Word value contained in `sts`

    # Getting DataType
    var dtype: DataType = DetectDataType(str, lineNum)
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
                result = NewWord(parseEscapedChar(s, lineNum))
            of NullType:
                # Checking if str is a label
                var found = false
                for l in labels:
                    if l.name == s:
                        result = NewWord(l.address)
                        found = true
                        break
                # Checking if str is a FromStackWord and should be taken from the first stack possition as Runtime
                if s == "$":
                    result = NewFromStackWord()

                elif not found:
                    LogError("At Line " & $lineNum & ": " & "DataType of '" & s & "' is unknown!")
                    quit(-1)
                
    except Exception as e:
        if e.name == "RangeDefect":
            # If value to big: ERROR
            LogError("At Line " & $lineNum & ": " & str & " value out of range!\n")
            quit(-1)