include "../asm/Bytecode.nim"

proc main() =
    var prog: Program = LoadFromFile("test.bc")
    for inst in prog.code:
        echo inst.InstName, inst.operand

main()