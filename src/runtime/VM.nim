import "../asm/DataTypes"
import "../asm/Bytecode"

# Virtual Machine definition
type CVM* = object
    stack: Stack
    stackSize: uint

    program: Program
    codeSize: uint

    memory: Memory
    memorySize: uint

proc CreateCVM*(program: Program): CVM =
    result.stackSize = 0
    result.program = program
    result.codeSize = uint(program.code.len)
    result.memorySize = 0