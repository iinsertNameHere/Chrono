import "asm/Bytecode"
import "utility/Logger"

import std/parseopt
import os

type Args = object
    programFile: string

proc InitArgs(): Args =
    result.programFile = ""

proc help() =
    echo "Usage: " & extractFilename(getAppFilename()) & " file"
    echo "Options:"
    echo "   ", "-h --help    >>   Show Help and exit"

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
                    else:
                        LogError("Unknown Option '" & parser.key & "'")
                        help()
                        quit(-1)
            of cmdArgument:
                if parser.key != "":
                    if args.programFile != "":
                        LogError("Redefinition of Program File!")
                        help()
                        quit(-1)

                    if splitFile(parser.key).ext != ".cro":
                        LogError("Program File is not a Chrono-Binary (.cro) file!")
                        quit(-1)

                    args.programFile = parser.key

proc main() =
    var args = InitArgs()
    args.ParseArgs()

    var prog: Program = LoadFromFile(args.programFile)
    for inst in prog.code:
        if inst.instType in NoArgInsts:
            echo inst.InstName
        else:
            echo inst.InstName, inst.operand

main()