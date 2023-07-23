import std/terminal

# Var that holds a bool, true if debug mode on
var debug* = false

proc LogSuccess*(msg: string) =
    ## Log a Success message
    stdout.styledWriteLine(fgGreen, "[SUCCESS] ", fgWhite, msg)

proc LogInfo*(msg: string) =
    ## Log a Info message
    stdout.styledWriteLine(fgBlue, "[INFO] ", fgWhite, msg)

proc LogDebug*(msg: string) =
    ## Log a Debug message
    if not debug:
        return
    stdout.styledWriteLine(fgMagenta, "[DEBUG] ", fgWhite, msg)

proc LogError*(msg: string) =
    ## Log a Success message
    stdout.styledWriteLine(fgRed, "[ERROR] ", fgWhite, msg)