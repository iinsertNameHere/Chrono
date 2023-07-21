include "../asm/Parser.nim"

proc main() =
    debug = false
    var prog = SourceToProgram("test.src")
    
    LogInfo("Writing compiled Program to file...")
    prog.writeToFile("test.bc")

    LogSuccess("Compilation Finished!")

main()