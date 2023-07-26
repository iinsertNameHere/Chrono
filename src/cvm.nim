import "runtime/VM"
import "runtime/Execution"
from "asm/Bytecode" import LoadProgramFromFile
import "utility/cvmArgParse"

import os

proc main() =
    # Parsing Args
    var args = InitArgs()
    args.ParseArgs()

    # Creating CVM instance
    var cvm = CreateCVM(LoadProgramFromFile(args.programFile))

    # Running CVM
    if args.decompile:
        cvm.Decompile(extractFilename(args.programFile.changeFileExt("decompiled.croasm")))
    else:
        cvm.Run()

main()