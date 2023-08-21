import "asm/parsing"
import "asm/bytecode"
import "utility/logger"
import "utility/nemoArgParse"
import "utility/globals.nim"

proc main() =
    # Parsing Args
    var args = InitArgs()
    args.ParseArgs()

    # Setting options
    logger.debug = args.debug
    globals.VerboseOutput = args.verbose

    # Parsing Source File to Bytecode
    var bytecode = CompileSourceFile(args.sourceFile)

    # if bytecode.labels.len != 0:
    #     echo "\nLABELS:"
    #     for label in bytecode.labels:
    #         echo label

    # echo "\nCODE:"
    # for inst in bytecode.code:
    #     echo inst


    
    # Writing bytecode to file
    LogInfo("Writing compiled Bytecode to file...")
    bytecode.WriteToFile(args.outputFile)

    LogSuccess("Compilation Finished!")

main()