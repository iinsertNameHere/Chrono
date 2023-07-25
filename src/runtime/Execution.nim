import "VM"
import "../asm/InstructionFunctions"
import "../utility/Logger"
import "../asm/Bytecode"

proc Run*(cvm: var CVM) =
    ## Function that executes the loaded .cro program
    var inst: Instruction
    while true:
        if cvm.cursorIndex > uint(cvm.program.len):
            LogError("Programm was not halted!")
            quit(-1)

        inst = cvm.program[cvm.cursorIndex]

        # echo inst.InstName
        # discard readLine(stdin)

        case inst.instType:
            of INST_NOP:
                cvm.cursorIndex += 1
            of INST_PUSH:
                cvm.INSTFN_PUSH(inst)
            of INST_DUP:
                cvm.INSTFN_DUP(inst)
            of INST_SWAP:
                cvm.INSTFN_SWAP(inst)
            of INST_DEL:
                cvm.INSTFN_DEL(inst)
            of INST_ADD:
                cvm.INSTFN_ADD(inst)
            of INST_SUB:
                cvm.INSTFN_SUB(inst)
            of INST_MUL:
                cvm.INSTFN_MUL(inst)
            of INST_DIV:
                cvm.INSTFN_DIV(inst)
            of INST_MOD:
                cvm.INSTFN_MOD(inst)
            of INST_STR:
                cvm.INSTFN_STR(inst)
            of INST_BAND:
                cvm.INSTFN_BAND(inst)
            of INST_BOR:
                cvm.INSTFN_BOR(inst)
            of INST_XOR:
                cvm.INSTFN_XOR(inst)
            of INST_SHL:
                cvm.INSTFN_SHL(inst)
            of INST_SHR:
                cvm.INSTFN_SHR(inst)
            of INST_AND:
                cvm.INSTFN_AND(inst)
            of INST_OR:
                cvm.INSTFN_OR(inst)
            of INST_JUMP:
                cvm.INSTFN_JUMP(inst)
            of INST_JUMPC:
                cvm.INSTFN_JUMPC(inst)
            of INST_CALL:
                cvm.INSTFN_CALL(inst)
            of INST_OUTPUT:
                cvm.INSTFN_OUTPUT(inst)
            of INST_DUMP:
                cvm.INSTFN_DUMP(inst)
            of INST_RETURN:
                cvm.INSTFN_RETURN(inst)
            of INST_LEN:
                cvm.INSTFN_LEN(inst)
            of INST_EQUAL:
                cvm.INSTFN_EQUAL(inst)
            of INST_NOT:
                cvm.INSTFN_NOT(inst)
            of INST_GREATER:
                cvm.INSTFN_GREATER(inst)
            of INST_LESS:
                cvm.INSTFN_LESS(inst)
            of INST_READ:
                cvm.INSTFN_READ(inst)
            of INST_WRITE:
                cvm.INSTFN_WRITE(inst)
            of INST_HALT:
                break
            else:
                LogError("No Function for Instruction " & inst.InstName)
                quit(-1)

proc Print*(cvm: CVM) =
    ## Function that print the Loaded .cro program
    for inst in cvm.program:
        if inst.instType in NoOperandInsts:
            echo inst.InstName
        else:
            echo inst.InstName & " " & $inst.operand.as_float