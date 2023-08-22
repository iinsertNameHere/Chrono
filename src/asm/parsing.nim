import "../utility/globals"
import "../utility/logger"
import "datatypes"
import "bytecode"

import std/streams
import strutils
import os

#########################################################################
## Tokens
#########################################################################
type TokenType = enum
    # Datatype Tokens
    tkInt,
    tkFloat,
    tkString,
    tkChar,

    # Preprocessor Tokens
    tkPreprocessorAnutation,
    tkLibString,
    tkComment,
    tkSkip,

    # CompileTime Tokens
    tkIdentifier,
    tkColon,
    tkNewLine,
    tkFile,
    tkEOF,

type Token = object
    ## Token Object
    typ: TokenType
    value: string

proc NewToken(typ: TokenType, value: string): Token =
    ## Create a new Token Object
    result.typ = typ
    result.value = value

proc isLetter(c: char): bool =
    ## Returns true if c is a valid Identifier letter 
    case c:
        of 'a'..'z', 'A'..'Z', '0'..'9', '_', '[', ']':
            return true
        else:
            return false

proc isDigit(c: char): bool =
    ## Returns true if c is a valid Identifier digit 
    case c:
        of '0'..'9', '.':
            return true
        else:
            return false

proc Tokenize(source: string): seq[Token] =
    ## Splits the source code string into tokens
    ## and returns them
    
    # Stuff to keep track of the line number
    var lineNum = 1
    CurrentFilePosition.SetCurrentLine(uint(lineNum))

    var lines = source.splitLines
    var maxLineNum = lines.len

    # Iterate Lines
    for line in lines:
        # Get tokens in line
        var lineTokens: seq[Token]
        var index = 0

        # Set line number
        lineNum.inc()
        CurrentFilePosition.SetCurrentLine(uint(lineNum))

        # Iterate chars in line
        while index < line.len:
            case line[index]:

                # Handle Identifiers
                of '_', '[', ']', 'a'..'z', 'A'..'Z':
                    var identifier = ""
                    while index < line.len and line[index].isLetter:
                        identifier.add(line[index])
                        index.inc()
                    
                    lineTokens.add(NewToken(tkIdentifier, identifier))

                # Handle Strings
                of '"':
                    if index < line.len:
                        var str = ""
                        
                        index.inc()
                        while index < line.len and line[index] != '"':
                            str &= $line[index]
                            index.inc()

                        if line[index] != '"':
                            LogError("Unterminated String", true)
                            quit(-1)
                        elif str.len == 0:
                            LogError("String is Empty!", true)
                            quit(-1)

                        index.inc()
                        lineTokens.add(NewToken(tkString, str))
                    else:
                        LogError("Unterminated String", true)
                        quit(-1)
                
                # Handle Lib Strings
                of '<':
                    if index < line.len:
                        var str = ""
                        
                        index.inc()
                        while index < line.len and line[index] != '>':
                            str &= $line[index]
                            index.inc()

                        if line[index] != '>':
                            LogError("Unterminated Lib String", true)
                            quit(-1)
                        elif str.len == 0:
                            LogError("Lib String is Empty!", true)
                            quit(-1)

                        index.inc()
                        lineTokens.add(NewToken(tkLibString, str))
                    else:
                        LogError("Unterminated Lib String", true)
                        quit(-1)

                # Handle Comments        
                of globals.CommentChar:
                    var str = ""
                    
                    index.inc()
                    while index < line.len:
                        str &= $line[index]
                        index.inc()

                    lineTokens.add(NewToken(tkComment, str))

                # Handle Chars
                of '\'':
                    var c = ""
                    if index < line.len:
                        index.inc()
                        while index < line.len and line[index] != '\'':
                            c &= $line[index]
                            index.inc()
                    
                    if line[index] != '\'':
                        LogError("Unterminated Char", true)
                        quit(-1)
                    elif c.len == 0:
                        LogError("Char is Empty!", true)
                        quit(1)
                    elif c.len > 1 and c[0] != '\\':
                        LogError("Char is to long!", true)
                        quit(1)
                    elif c.len > 2 and c[0] == '\\':
                        LogError("Char is to long!", true)
                        quit(1)
                    elif c.len < 2 and c[0] == '\\':
                        LogError("EscapedChar is to short!", true)
                        quit(1)
                    
                    var final = c
                    if c[0] == '\\':
                        final = $parseEscapedChar(c)

                    index.inc()
                    lineTokens.add(NewToken(tkChar, final))

                # Handle Preprocessor Anutations
                of '@':
                    index.inc()
                    lineTokens.add(NewToken(tkPreprocessorAnutation, "@"))
                
                # Handle Numbers
                of '0'..'9':
                    var lit = ""
                    while index < line.len and line[index].isDigit:
                        lit.add(line[index])
                        index.inc()

                    if '.' in lit:
                        try:
                            discard parseFloat(lit)
                        except:
                            LogError("'$#' is not a valid float!" % lit, true)
                            quit(-1)
                        lineTokens.add(NewToken(tkFloat, lit))
                    else:
                        try:
                            discard parseInt(lit)
                        except:
                            LogError("'$#' is not a valid int!" % lit, true)
                            quit(-1)
                        lineTokens.add(NewToken(tkInt, lit))

                # Handle Single Chars
                of ':':
                    lineTokens.add(NewToken(tkColon, $line[index]))
                    index.inc()
                of ' ', '\t':
                    index.inc()

                # Error Case
                else:
                    LogError("'$#' is not defined!" % $line[index], true)
                    quit(-1)

        # Handle New lines and EndOfFile
        if lineNum <= maxLineNum:
            lineTokens.add(NewToken(tkNewLine, "\n"))
        else:
            lineTokens.add(NewToken(tkEOF, "EOF"))

        # Add tokens to result
        result &= lineTokens

proc AddFile(tokensA: var seq[Token], fileName: string, tokensB: seq[Token]) =
    # Adds tokensB to tokensA seperated by a File token to indicate a new file to the Compiler
    tokensA.add(NewToken(tkFile, fileName))
    tokensA &= tokensB

#########################################################################
## Compilation
#########################################################################
proc PreProcess(bytecode: var Bytecode, tokens: var seq[Token]) =
    ## Handles PreprocessorAnutation's
    bytecode.includes = @[]

    # Stuff to keep track of the line number
    CurrentFilePosition.SetCurrentLine(1)
    var lineNum = 1

    ## Iterate Tokens
    var index = 0
    while true:
        var token: Token = tokens[index]

        # If EndOfFile, end iteration
        if token.typ == tkEOF:
            break
        
        # If NewLine, inc line number
        elif token.typ == tkNewLine:
            lineNum.inc()
            CurrentFilePosition.SetCurrentLine(uint(lineNum))

        # Skip Comments
        elif token.typ == tkComment:
            if globals.VerboseOutput: LogDebug("Skiped Comment!", true)

        # Handle Preprocessor Anutations
        elif token.typ == tkPreprocessorAnutation:
            # Get the next Token
            index.inc()
            var nextToken = tokens[index]

            # Check if token is Identifier Token
            if nextToken.typ != tkIdentifier:
                LogError("Expected Identifier after \"@\"", true)
                quit(1)
            
            # Handle Identifiers
            if nextToken.value == "include":

                # Get next Token
                index.inc()
                nextToken = tokens[index]
                
                var includePath: string

                # Get path of file to Include
                if nextToken.typ == tkString:
                    includePath = nextToken.value
                elif nextToken.typ == tkLibString:
                    includePath = joinPath(globals.LibDirectory, nextToken.value & ".nemo")
                else:
                    LogError("Expected Lib Path after include", true)
                    quit(1)

                # Add include file path to includes
                if not (includePath in bytecode.includes):
                    bytecode.includes.add(includePath)

                # Mark the Handled tokens to be skipt in Compilation
                for i in countdown(2, 0):
                    tokens[index-i].typ = tkSkip
            else:
                LogError("Unknown Identifier \"$#\"" % nextToken.value)
                quit(1)
        index.inc()

proc ParseString(bytecode: var Bytecode, str: string) =
    ## Parses a string to "push char" instructions
    var skipNext: bool = false

    var finalString: string

    # Iterate string
    for i in countup(0, str.len - 1):
        # If skipNext, skip
        if skipNext:
            skipNext = false
            continue

        # Get char by index i
        var c = str[i]

        # Handle Escaped Chars
        if c == '\\' and i < str.len:
            c = parseEscapedChar(str[i..i+1])
            skipNext = true

        finalString &= c

    # Add string to bytecode in reverse order
    for i in countdown(finalString.len - 1, 0):
        bytecode.code.add(NewInst(INST_PUSH, NewWord(finalString[i])))

proc ParseLabels(bytecode: var Bytecode, tokens: var seq[Token]) =
    ## Functions that parses Labels
    bytecode.code = @[]
    bytecode.labels = @[]

    var instType = INST_ERROR

    # Stuff to keep track of the line number
    CurrentFilePosition.SetCurrentLine(1)
    var lineNum = 1

    # Iterate Tokens
    var index = 0
    while true:
        var token: Token = tokens[index]

        # Check if token is Instruction
        if token.typ == tkIdentifier:
            instType = GetInstTypeByName(token.value)
        else:
            instType = INST_ERROR

        # If EndOfFile and next token not File Token, end iteration
        if token.typ == tkEOF:
            if index >= tokens.len-1:
                break   
            elif tokens[index+1].typ != tkFile:
                break

        # If NewLine, inc line number
        elif token.typ == tkNewLine:
            lineNum.inc()
            CurrentFilePosition.SetCurrentLine(uint(lineNum))

        # Skip Comments
        elif token.typ == tkComment:
            if globals.VerboseOutput: LogDebug("Skiped Comment!", true)

        # If File Token, change CurrentFile Info to the new File
        elif token.typ == tkFile:
            CurrentFilePosition.SetCurrentFile(token.value)
            CurrentFilePosition.SetCurrentLine(1)
            lineNum = 1

        # Skip
        elif token.typ == tkSkip:
            if globals.VerboseOutput: LogDebug("Skiped Token!", true)

        # Handle Identifiers
        elif token.typ == tkIdentifier:
            # Skip Instruction
            if instType != INST_ERROR:
                    if instType.takesOperand():
                        if index+1 >= tokens.len:
                            LogError("Expected operand after instruction \"$#\"" % token.value, true)
                            quit(1)

                        index.inc()
                        var nextToken = tokens[index]

                        if nextToken.typ == tkString:
                            bytecode.ParseString(nextToken.value)
                        else:
                            bytecode.code.add(NewInst(INST_NOP, NewWord(0)))
                    else:
                        bytecode.code.add(NewInst(INST_NOP, NewWord(0)))
            
            # Handle Labels
            else:
                if index+1 >= tokens.len:
                    LogError("Unknown Identifier \"$#\"" % token.value, true)
                    quit(1)

                # Get Next token
                index.inc()
                var nextToken = tokens[index]

                # If next token is Colon, Register new Label
                if nextToken.typ == tkColon:
                    bytecode.RegisterLabel(token.value, uint(bytecode.code.len))
                    LogDebug("RegisterdLabel \"$#\"" % token.value, true)

                    # Mark the Handled tokens to be skipt in Compilation
                    for i in countdown(1, 0):
                        tokens[index-i].typ = tkSkip
                else:
                    LogError("Unknown Identifier \"$#\"" % token.value, true)
                    quit(1)

        else:
            LogError("Unexpected token \"$#\"" % $token.typ, true)
            quit(1)

        index.inc()

proc Compile(bytecode: var Bytecode, tokens: seq[Token]) =
    ## Functions that Parses Tokens
    
    bytecode.code = @[]
    var instType = INST_ERROR

    # Stuff to keep track of the line number
    CurrentFilePosition.SetCurrentLine(1)
    var lineNum = 1

    # Iterate Tokens
    var index = 0
    while true:
        var token: Token = tokens[index]

        # Check if token is Instruction
        if token.typ == tkIdentifier:
            instType = GetInstTypeByName(token.value)
        else:
            instType = INST_ERROR

        # If EndOfFile and next token not File Token, end iteration
        if token.typ == tkEOF:
            if index >= tokens.len-1:
                break   
            elif tokens[index+1].typ != tkFile:
                break
        
        # If NewLine, inc line number
        elif token.typ == tkNewLine:
            lineNum.inc()
            CurrentFilePosition.SetCurrentLine(uint(lineNum))

        # Skip Comments
        elif token.typ == tkComment:
            if globals.VerboseOutput: LogDebug("Skiped Comment!", true)

        # If File Token, change CurrentFile Info to the new File
        elif token.typ == tkFile:
            CurrentFilePosition.SetCurrentFile(token.value)
            CurrentFilePosition.SetCurrentLine(1)
            lineNum = 1

        # Skip        
        elif token.typ == tkSkip:
            if globals.VerboseOutput: LogDebug("Skiped Token!", true)

        # Handle Identifiers
        elif token.typ == tkIdentifier:
            # Handle Instruction
            if instType != INST_ERROR:
                # Handle Operand Insts
                if instType.takesOperand:
                    if index+1 >= tokens.len:
                        LogError("Expected operand after instruction \"$#\"" % token.value, true)
                        quit(1)
                    
                    # Get next Token
                    index.inc()
                    var operandToken = tokens[index]

                    # Handle int operand
                    if operandToken.typ == tkInt:
                        bytecode.code.add(NewInst(instType, NewWord(parseInt(operandToken.value))))

                    # Handle float operand
                    elif operandToken.typ == tkFloat:
                        bytecode.code.add(NewInst(instType, NewWord(parseFloat(operandToken.value))))
                    
                    # Handle char operand
                    elif operandToken.typ == tkChar:
                        bytecode.code.add(NewInst(instType, NewWord(operandToken.value[0])))
                    
                    # Handle String operand
                    elif operandToken.typ == tkString:
                        bytecode.ParseString(operandToken.value)
                    
                    # Handle Identifier operand
                    elif operandToken.typ == tkIdentifier:
                        # Handle bool operands
                        if operandToken.value == "true":
                            bytecode.code.add(NewInst(instType, NewWord(true)))
                        elif operandToken.value == "false":
                            bytecode.code.add(NewInst(instType, NewWord(false)))
                        
                        # Handle Label operands
                        else:
                            var labelAddress = bytecode.hasLabel(operandToken.value)
                            if labelAddress >= 0:
                                bytecode.code.add(NewInst(instType, NewWord(labelAddress)))
                            else:
                                LogError("Expected operand after instruction \"$#\"" % token.value, true)
                                quit(1)
                    else:
                        LogError("Expected operand after instruction \"$#\"" % token.value, true)
                        quit(1)

                # Handle Insts without operand
                else:
                    bytecode.code.add(NewInst(instType, NewWord(0)))
            else:
                LogError("Unknown Identifier \"$#\"" % token.value, true)
                quit(1)
        else:
            LogError("Unexpected token \"$#\"" % $token.typ, true)
            quit(1)

        index.inc()

proc TokenizeSourceFile(path: string): seq[Token] =
    var fstrm = newFileStream(path, fmRead)
    if isNil(fstrm):
        LogError("Could not open File Stream to file: '$#'!" % (path))
        quit(-1)

    var fileName = extractFilename(path)
    CurrentFilePosition.SetCurrentFile(fileName)

    var source = fstrm.readAll()
    if source.len < 1:
        LogError("File \"$#\" is Empty!" % fileName)
        quit(-1)
    
    fstrm.close()

    LogDebug("Tokenizing \"$#\"..." % fileName)
    result = Tokenize(source)

proc HandleIncludes(includePaths: seq[string]): seq[Token] =
    var includeTokens: seq[Token]
    var includeBytecode: Bytecode
    for includePath in includePaths:
        LogDebug("Including file \"$#\"..." % includePath)
        includeTokens = TokenizeSourceFile(includePath)
        includeBytecode.PreProcess(includeTokens)
        result &= HandleIncludes(includeBytecode.includes)
        result.AddFile(extractFilename(includePath), includeTokens)

proc CompileSourceFile*(path: string): Bytecode =
    var mainTokens = TokenizeSourceFile(path)

    LogDebug("Running Preprocessor...")
    result.PreProcess(mainTokens)

    LogDebug("Parsing Includes...")
    var tokens = HandleIncludes(result.includes)

    tokens.AddFile(extractFilename(path), mainTokens)

    LogDebug("Parsing Labels...")
    result.ParseLabels(tokens)

    LogDebug("Compiling...")
    result.Compile(tokens)