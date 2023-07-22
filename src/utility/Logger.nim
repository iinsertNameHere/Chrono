import std/terminal

var debug* = false

proc LogSuccess*(msg: string) =
    stdout.styledWriteLine(fgGreen, "[SUCCESS] ", fgWhite, msg)

proc LogInfo*(msg: string) =
    stdout.styledWriteLine(fgBlue, "[INFO] ", fgWhite, msg)

proc LogDebug*(msg: string) =
    if not debug:
        return
    stdout.styledWriteLine(fgMagenta, "[DEBUG] ", fgWhite, msg)

proc LogError*(msg: string) =
    stdout.styledWriteLine(fgRed, "[ERROR] ", fgWhite, msg)