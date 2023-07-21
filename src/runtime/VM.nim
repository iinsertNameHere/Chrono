include "../asm/DataTypes.nim"
include "../asm/Bytecode.nim"

# Virtual Machine definition
type CVM = object
    stack: Stack
    stackSize: uint

    program: Program
    programSize: uint

    memory: Memory
    memorySize: uint

proc CreateCVM(program: Program): CVM =
    result.stackSize = 0
    result.program = program
    result.programSize = uint(program.len)
    result.memorySize = 0