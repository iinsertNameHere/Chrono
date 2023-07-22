import "asm/Parsing"
import "asm/Bytecode"
import "utility/Logger"

import strutils
import std/parseopt
import os

type Args = object
    debug: bool
    sourceFile: string
    outputFile: string

proc InitArgs(): Args =
    result.debug = false
    result.sourceFile = ""
    result.outputFile = ""

proc help() =
    echo "Usage: " & extractFilename(getAppFilename()) & " [options] file"
    echo "Options:"
    echo "   ", "-h --help    >>   Show Help and exit"
    echo "   ", "-d --debug   >>   Enabled Debug output"
    echo "   ", "-o --output  >>   Define Output File"
    echo ""

proc ParseArgs(args: var Args) =
    var parser = initOptParser(commandLineParams())
    while true:
        parser.next()
        case parser.kind:
            of cmdEnd: break
            of cmdShortOption, cmdLongOption:
                case parser.key:
                    of "h", "help":
                        help()
                        quit(0)
                    of "d", "debug":
                        args.debug = true
                    of "o", "output":
                        if parser.val.strip() == "":
                            LogError(parser.key & "No Output File given!")
                            help()
                            quit(-1)
                        args.outputFile = parser.val
                    else:
                        LogError("Unknown Option '" & parser.key & "'")
                        help()
                        quit(-1)
            of cmdArgument:
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
        LogError("Source File not set!")
        help()
        quit(-1)

    if args.outputFile.strip() == "":
        args.outputFile = extractFilename(args.sourceFile.changeFileExt("cro"))

proc main() =
    var args = InitArgs()
    args.ParseArgs()

    Logger.debug = args.debug

    var prog = SourceToProgram(args.sourceFile)
    
    LogInfo("Writing compiled Program to file...")
    prog.writeToFile(args.outputFile)

    LogSuccess("Compilation Finished!")

main()