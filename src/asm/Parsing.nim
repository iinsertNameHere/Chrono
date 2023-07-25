import "Bytecode"
import "../utility/Logger"
import "DataTypes"

import strutils
import std/streams

type TokenType = enum
    ## All Token Types suported by croasm
    NoOperandInstructionToken
    InstructionToken
    CommentToken
    EmptyToken
    LabelToken
    UnknownToken
    StringToken

type Token = object
    ## Object that hold an identifier string, an addon string and a TokenType
    identifier: string
    addon: string
    tType: TokenType 

const CommentChar: char = ';'

proc Tokenize(str: string, lineNum: int): Token =
    ## Parses a Token contained in 'str'
    ## If str empty or starts with comment symbol:
    ##    Return: Token of type EmptyToken
    ## Else If str is valid token:
    ##    Return: Token with correct type
    ## Else: 
    ##    Return: Token of type UnknowToken
    
    # Check if token empty or starts with CommentChar

    if str.len < 1 or str.startsWith(CommentChar):
        result.tType = EmptyToken
        return

    # Check if Token is StringToken
    if str.startsWith("@\"") and str.endsWith('"'):
        if str.len < 4:
            LogError("At Line " & $lineNum & ": " & "String is empty and could not be Parsed!")
            quit(-1)

        result.tType = StringToken
        result.identifier = "@"

        result.addon = str
        result.addon.removePrefix("@\"")
        result.addon.removeSuffix('"')
        return
    
    # Spliting str to token
    var token = str.split(' ')
    if token.len > 2:
        token = token[0..1]
    
    if token.len < 1:
        result.tType = EmptyToken
        return

    # Getting InstructionType. If not a instruction, instType = INST_ERROR
    var instType = GetInstTypeByName(token[0])
    
    # If str only has one part and is valid inst,
    # Return NoOperandInstructionToken 
    if token.len < 2 and instType != INST_ERROR:
        result.identifier = token[0]
        result.tType = NoOperandInstructionToken

    # If str only has more one part and is valid inst,
    # Return InstructionToken 
    elif token.len > 1 and instType != INST_ERROR:
        result.identifier = token[0]
        result.addon = token[1]
        result.tType = InstructionToken
    
    # Check if token is LabelToken
    elif token[0].endsWith(':'):
        var name = token[0]
        name.removeSuffix(':')
        result.identifier = name
        result.addon = ":"
        result.tType = LabelToken
    
    # Token is not Valid
    else:
        result.tType = UnknownToken
        LogError("At Line " & $lineNum & ": " & "\"" & str & "\" could not be Parsed!")
        quit(-1)

proc ParseString(bytecode: var Bytecode, str: string, lineNum: int) =
    ## Function parses a string to "push char" instructions
    var skipNext: bool = false

    # Iterate string
    var finalString: string

    for i in countup(0, str.len - 1):
        # If skipNext, skip
        if skipNext:
            skipNext = false
            continue

        # Get char by index i
        var c = str[i]

        # Handle Escaped Chars
        if c == '\\' and i < str.len:
            c = parseEscapedChar(str[i..i+1], lineNum)
            skipNext = true

        finalString &= c

    for i in countdown(finalString.len - 1, 0):
        bytecode.code.add(NewInst(INST_PUSH, NewWord(finalString[i])))
    
proc PreParse(bytecode: var Bytecode, source: string) =
    ## Functions that Parses Labels
    bytecode.code = @[]
    bytecode.labels = @[]

    ## Iterate lines of the source code
    var lineNum = 0
    for l in splitLines(source):
        lineNum += 1
        var line = l.strip()
        
        # Tokenize current line
        var token: Token = Tokenize(line, lineNum)
        
        # If EmptyToken, skip
        if token.tType == EmptyToken:
            continue
        
        # If StringToken, skip
        if token.tType == StringToken:
            bytecode.ParseString(token.addon, lineNum)
            continue
        
        # If InstructionToken, skip
        elif token.tType == NoOperandInstructionToken or token.tType == InstructionToken:
            bytecode.code.add(NewInst(INST_NOP, NewWord(0)))
            continue
        
        # If LabelToken, register new label
        elif token.tType == LabelToken:
            if GetInstTypeByName(token.identifier) != INST_ERROR:
                LogError("At Line " & $lineNum & ": " & token.identifier & " is an Instruction and can't be used as Label!")
                quit(-1)

            const invalidLabelChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789[]()_-"
            for c in token.identifier.toUpper:
                if not (c in invalidLabelChars):
                    LogError("At Line " & $lineNum & ": " & c & " can't be used in Label names!")
                    quit(-1)

            bytecode.RegisterLabel(token.identifier, bytecode.code.len, lineNum)
            LogDebug("Registerd Label '" & token.identifier & "' with addr " & $bytecode.code.len)
            continue

proc Parse(bytecode: var Bytecode, source: string) =
    ## Function that Parses source code to Bytecode
    bytecode.code = @[]

    ## Iterate lines of the source code
    var lineNum = 0
    for l in splitLines(source):
        lineNum += 1
        var line = l.strip()

        # Tokenize line
        var token: Token = Tokenize(line, lineNum)

        # Get instructionType of token identifier
        var instType = GetInstTypeByName(token.identifier)
        
        # If EmptyToken, skip
        if token.tType == EmptyToken:
            continue
        
        # If StringToken, ParseString
        if token.tType == StringToken:
            bytecode.ParseString(token.addon, lineNum)
            continue

        # If No Operand InstructionToken, add Instruction without operand
        elif token.tType == NoOperandInstructionToken:
            if not (instType in NoOperandInsts):
                LogError("At Line " & $lineNum & ":" & "Instruction '" & token.identifier.toUpper() & "' takes an argument!")
                quit(-1)
            bytecode.code.add(NewInst(instType, NewWord(0))) 
            continue

        # If InstructionToken, add Instruction with operand
        elif token.tType == InstructionToken:
            if (instType in NoOperandInsts): 
                LogError("At Line " & $lineNum & ":" & "Instruction '" & token.identifier.toUpper() & "' takes no argument!")
                quit(-1)
            bytecode.code.add(NewInst(instType, parseWord(token.addon, bytecode.labels, lineNum)))
            continue

        # If LabelToken, skip
        elif token.tType == LabelToken:
            continue

proc ParseSourceFile*(path: string): Bytecode =
    var fstrm = newFileStream(path, fmRead)
    if isNil(fstrm):
        LogError("Could not open File Stream to file: '" & path & "'!")
        quit(-1)

    var source = fstrm.readAll()

    if source.len < 1:
        LogError("Source file is Empty!")
        quit(-1)

    LogDebug("Running PreParser...")
    result.PreParse(source)

    LogDebug("Parsing...")
    result.Parse(source)

    LogDebug("Parsing finished...")