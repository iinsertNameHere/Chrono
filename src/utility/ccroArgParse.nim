import "Logger"

import os
import strutils
import std/parseopt

type Args* = object
    ## Opject that holds all Arguments as Vars
    debug*: bool
    sourceFile*: string
    outputFile*: string

proc InitArgs*(): Args =
    ## Function that Initializes an Args instance
    result.debug = false
    result.sourceFile = ""
    result.outputFile = ""

proc help() =
    ## Function that print help list to console
    echo "Usage: " & extractFilename(getAppFilename()) & " [options] file"
    echo "Options:"
    echo "   ", "-h --help    >>   Show Help and exit"
    echo "   ", "-d --debug   >>   Enabled Debug output"
    echo "   ", "-o --output  >>   Define Output File"
    echo ""

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
                    of "d", "debug": # -d and --debug
                        args.debug = true
                    of "o", "output": # -o and --output
                        if parser.val.strip() == "":
                            LogError("Missing Output File!")
                            help()
                            quit(-1)
                        args.outputFile = parser.val
                    else:
                        LogError("Unknown Option '$#'" % (parser.key))
                        help()
                        quit(-1)
            of cmdArgument: # positional args
                if parser.key != "":
                    if args.sourceFile != "":
                        LogError("Redefinition of Source File!")
                        help()
                        quit(-1)

                    if splitFile(parser.key).ext != ".croasm":
                        LogError("Source File is not a Chrono-Assembly (.croasm) file!")
                        quit(-1)

                    args.sourceFile = parser.key

    if args.sourceFile.strip() == "":
        LogError("Missing Source File!")
        help()
        quit(-1)

    if args.outputFile.strip() == "":
        args.outputFile = extractFilename(args.sourceFile.changeFileExt("cro"))