import "runtime/vm"
import "runtime/execution"
import "asm/bytecode"
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
        cvm.Decompile(extractFilename(args.programFile.changeFileExt("decompiled.nemo")), args.decompileToStdout)
    else:
        cvm.Run()

main()