import "runtime/VM"
import "runtime/Execution"
from "asm/Bytecode" import LoadProgramFromFile
import "utility/cvmArgParse"

proc main() =
    # Parsing Args
    var args = InitArgs()
    args.ParseArgs()

    # Creating CVM instance
    var cvm = CreateCVM(LoadProgramFromFile(args.programFile))

    # Running CVM
    cvm.Run()

main()