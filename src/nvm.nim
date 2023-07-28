import "runtime/VM"
import "runtime/Execution"
from "asm/Bytecode" import LoadProgramFromFile
import "utility/nvmArgParse"

import os

proc main() =
    # Parsing Args
    var args = InitArgs()
    args.ParseArgs()

    # Creating CVM instance
    var cvm = CreateCVM(LoadProgramFromFile(args.programFile))

    # Running CVM
    if args.decompile:
        cvm.Decompile(extractFilename(args.programFile.changeFileExt("decompiled.nemo")))
    else:
        cvm.Run()

main()