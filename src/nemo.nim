import "asm/Parsing"
import "asm/Bytecode"
import "utility/Logger"
import "utility/nemoArgParse"

proc main() =
    # Parsing Args
    var args = InitArgs()
    args.ParseArgs()

    # Setting options
    Logger.debug = args.debug

    # Parsing Source File to Bytecode
    var bytecode = ParseSourceFile(args.sourceFile)
    
    # Writing bytecode to file
    LogInfo("Writing compiled Bytecode to file...")
    bytecode.WriteToFile(args.outputFile)

    LogSuccess("Compilation Finished!")

main()