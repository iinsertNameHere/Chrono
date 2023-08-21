import "logger"

import std/parseopt
import strutils
import os

type Args* = object
    ## Opject that holds all Arguments as Vars
    programFile*: string
    decompile*: bool
    decompileToStdout*: bool

proc InitArgs*(): Args =
    ## Function that Initializes an Args instance
    result.programFile = ""
    result.decompile = false
    result.decompileToStdout = false

proc help() =
    ## Function that print help list to console
    echo "Usage: " & extractFilename(getAppFilename()) & "[options] file"
    echo "Options:"
    echo "   ", "-h --help             >>   Show Help and exit"
    echo "   ", "-d --decompile        >>   Decompiles the program"
    echo "   ", "--decompile-to-stdout >>   Decompiles the program and prints it to stdout"

proc ParseArgs*(args: var Args) =
    ## Function that Parses the commandline-args to an Args object
    var parser = initOptParser(commandLineParams())
    while true:
        parser.next()
        case parser.kind: 
            of cmdEnd: break # Break loop if no more args
            of cmdShortOption, cmdLongOption: # Parse -- and - Args
                case parser.key:
                    of "h", "help": # -h and --help
                        help()
                        quit(0)
                    of "d", "decompile": # -d and --decompile
                        args.decompile = true
                    of "decompile-to-stdout": # -d and --decompile
                        args.decompile = true
                        args.decompileToStdout = true
                    else:
                        LogError("Unknown Option \"$#\"" % (parser.key))
                        help()
                        quit(-1)
            of cmdArgument: # positional args
                if parser.key != "":
                    if args.programFile != "":
                        LogError("Redefinition of Program File!")
                        help()
                        quit(-1)

                    if splitFile(parser.key).ext != ".nce":
                        LogError("Program File is not a Chrono-Binary (.nce) file!")
                        quit(-1)

                    args.programFile = parser.key

    if args.programFile.strip() == "":
        LogError("Missing Source File!")
        help()
        quit(-1)