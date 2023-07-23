import "../asm/DataTypes"
import "../asm/Bytecode"

type CVM* = object
    ## Virtual Machine that holds a Stack, a program, a programSize and a memory 
    stack*: Stack

    program*: Program
    programSize: uint

    memory*: Memory

proc CreateCVM*(program: Program): CVM =
    ## Function that Creates a new CVM instance
    result.program = program
    result.programSize = uint(program.len)