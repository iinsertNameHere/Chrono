import "runtime/VM"
from "asm/Bytecode" import LoadProgramFromFile
import "utility/cvmArgParse"

proc main() =
    var args = InitArgs()
    args.ParseArgs()

    var cvm = CreateCVM(LoadProgramFromFile(args.programFile))
main()