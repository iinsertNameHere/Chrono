import std/terminal

# Var that holds a bool, true if debug mode on
var debug* = false

type FilePosition* = object
    ## Object that holds the current position in a source file
    currentFile*: string
    currentLine*: uint

var CurrentFilePosition*: FilePosition

proc SetCurrentFile*(fp: var FilePosition, currentFile: string) =
    fp.currentFile = currentFile

proc SetCurrentLine*(fp: var FilePosition, currentLine: uint) =
    fp.currentLine = currentLine

proc LogSuccess*(msg: string, positional: bool = false) =
    ## Log a Success message
    if positional:
        stdout.styledWriteLine(fgGreen, "[Success/", CurrentFilePosition.currentFile & ":", $CurrentFilePosition.currentLine & "]: ", fgWhite, msg)
        return

    stdout.styledWriteLine(fgGreen, "[SUCCESS] ", fgWhite, msg)

proc LogInfo*(msg: string, positional: bool  = false) =
    ## Log a Info message
    if positional:
        stdout.styledWriteLine(fgBlue, "[Hint/", CurrentFilePosition.currentFile & ":", $CurrentFilePosition.currentLine & "]: ", fgWhite, msg)
        return

    stdout.styledWriteLine(fgBlue, "[Info] ", fgWhite, msg)

proc LogDebug*(msg: string, positional: bool = false) =
    ## Log a Debug message
    if not debug:
        return

    if positional:
        stdout.styledWriteLine(fgMagenta, "[Debug/", CurrentFilePosition.currentFile & ":", $CurrentFilePosition.currentLine & "]: ", fgWhite, msg)
        return

    stdout.styledWriteLine(fgMagenta, "[DEBUG] ", fgWhite, msg)

proc LogError*(msg: string, positional: bool  = false) =
    ## Log a Success message
    if positional:
        stdout.styledWriteLine(fgRed, "[Error/", CurrentFilePosition.currentFile & ":", $CurrentFilePosition.currentLine & "]: ", fgWhite, msg)
        return

    stdout.styledWriteLine(fgRed, "[ERROR] ", fgWhite, msg)