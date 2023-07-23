import "Logger"

import std/parseopt
import os

type Args* = object
    ## Opject that holds all Arguments as Vars
    programFile*: string

proc InitArgs*(): Args =
    ## Function that Initializes an Args instance
    result.programFile = ""

proc help() =
    ## Function that print help list to console
    echo "Usage: " & extractFilename(getAppFilename()) & " file"
    echo "Options:"
    echo "   ", "-h --help    >>   Show Help and exit"

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
                    else:
                        LogError("Unknown Option '" & parser.key & "'")
                        help()
                        quit(-1)
            of cmdArgument: # positional args
                if parser.key != "":
                    if args.programFile != "":
                        LogError("Redefinition of Program File!")
                        help()
                        quit(-1)

                    if splitFile(parser.key).ext != ".cro":
                        LogError("Program File is not a Chrono-Binary (.cro) file!")
                        quit(-1)

                    args.programFile = parser.key