import "Bytecode"
import "DataTypes"
import "../runtime/VM"
import "../utility/Logger"

proc INSTFN_PUSH*(cvm: var CVM, inst: Instruction) =
    ## Adds value to Stack at index 0
    if inst.operand.fromStack:
        LogError("The FromStack operand is not supported for " & inst.InstName)
        quit(-1)

    cvm.stack.PushBack(inst.operand)

    cvm.cursorIndex += 1

proc INSTFN_DUP*(cvm: var CVM, inst: Instruction) =
    ## Duplicates value at Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var dupIndex: int
    if inst.operand.fromStack:
        dupIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        dupIndex = inst.operand.as_numb

    if dupIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " operand out of stack range!")
        quit(-1)

    cvm.stack.PushBack(cvm.stack[dupIndex])

    cvm.cursorIndex += 1

proc INSTFN_SWAP*(cvm: var CVM, inst: Instruction) =
    ## Swaps Stack[0] with Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var swapVal = cvm.stack[0]
    var swapWithIndex: int

    if inst.operand.fromStack:
        swapWithIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        swapWithIndex = inst.operand.as_numb

    if swapWithIndex == 0:
        LogError(inst.InstName & $inst.operand & " Illegal swap Operation!")

    if swapWithIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    cvm.stack[0] = cvm.stack[swapWithIndex]
    cvm.stack[swapWithIndex] = swapVal

    cvm.cursorIndex += 1

proc INSTFN_DEL*(cvm: var CVM, inst: Instruction) =
    ## Deletes Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var delAtindex: int
    if inst.operand.fromStack:
        delAtindex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        delAtindex = inst.operand.as_numb

    if delAtindex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    cvm.stack.delete(delAtindex)

    cvm.cursorIndex += 1

proc INSTFN_ADD*(cvm: var CVM, inst: Instruction) =
    ## Adds Stack[Given Operand] to Stack[0]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var addToVal = cvm.stack[0].as_float
    var toAddIndex: int
    
    if inst.operand.fromStack:
        toAddIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        toAddIndex = inst.operand.as_numb

    if toAddIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if toAddIndex < 1:
        LogError(inst.InstName & $inst.operand & " Operand can't be 0!")
        quit(-1)

    cvm.stack.PushBack(NewWord(addToVal + cvm.stack[toAddIndex].as_float))
    cvm.stack.delete(toAddIndex)
    cvm.stack.delete(1)

    cvm.cursorIndex += 1

proc INSTFN_SUB*(cvm: var CVM, inst: Instruction) =
    ## Subtracts Stack[Given Operand] from Stack[0]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var subFromVal = cvm.stack[0].as_float
    var toSubIndex: int
    
    if inst.operand.fromStack:
        toSubIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        toSubIndex = inst.operand.as_numb

    if toSubIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if toSubIndex < 1:
        LogError(inst.InstName & $inst.operand & " Operand can't be 0!")
        quit(-1)

    var w = NewWord(subFromVal - cvm.stack[toSubIndex].as_float)

    cvm.stack.PushBack(w)
    cvm.stack.delete(toSubIndex)
    cvm.stack.delete(1)

    cvm.cursorIndex += 1

proc INSTFN_MUL*(cvm: var CVM, inst: Instruction) =
    ## Multiplies Stack[0] by Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var mulWithVal = cvm.stack[0].as_float
    var mulByIndex: int
    
    if inst.operand.fromStack:
        mulByIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        mulByIndex = inst.operand.as_numb

    if mulByIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if mulByIndex < 1:
        LogError(inst.InstName & $inst.operand & " Operand can't be 0!")
        quit(-1)

    cvm.stack.PushBack(NewWord(mulWithVal * cvm.stack[mulByIndex].as_float))
    cvm.stack.delete(mulByIndex)
    cvm.stack.delete(1)

    cvm.cursorIndex += 1

proc INSTFN_DIV*(cvm: var CVM, inst: Instruction) =
    ## Divides Stack[0] by Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var toDivVal = cvm.stack[0].as_float
    var divByIndex: int
    
    if inst.operand.fromStack:
        divByIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        divByIndex = inst.operand.as_numb

    if divByIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if toDivVal == 0.0 or cvm.stack[divByIndex].as_float == 0.0:
        LogError(inst.InstName & $inst.operand & " Division by zero!")
        quit(-1)

    if divByIndex < 1:
        LogError(inst.InstName & $inst.operand & " Operand can't be 0!")
        quit(-1)

    cvm.stack.PushBack(NewWord(toDivVal / cvm.stack[divByIndex].as_float))
    cvm.stack.delete(divByIndex)
    cvm.stack.delete(1)

    cvm.cursorIndex += 1

proc INSTFN_MOD*(cvm: var CVM, inst: Instruction) =
    ## Performs a Modulu operation on Stack[0] using Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var toModVal = cvm.stack[0].as_numb
    var modUsingIndex: int
    
    if inst.operand.fromStack:
        modUsingIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        modUsingIndex = inst.operand.as_numb

    if modUsingIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if modUsingIndex < 1:
        LogError(inst.InstName & $inst.operand & " Operand can't be 0!")
        quit(-1)

    cvm.stack.PushBack(NewWord(toModVal mod cvm.stack[modUsingIndex].as_numb))
    cvm.stack.delete(modUsingIndex)
    cvm.stack.delete(1)

    cvm.cursorIndex += 1

proc INSTFN_STR*(cvm: var CVM, inst: Instruction) =
    ## Convertes Stack[0] to str and pushes each char to stack
    ## Op true = as_numb
    ## OP false = as_float
    
    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    if inst.operand.as_bool:
        var valToStr: int = cvm.stack[0].as_numb
        var str = $valToStr

        cvm.stack.delete(0)

        for c in str:
            cvm.stack.PushBack(NewWord(c))
    else:
        var valToStr: float = cvm.stack[0].as_float
        var str = $valToStr

        cvm.stack.delete(0)

        for c in str:
            cvm.stack.PushBack(NewWord(c))

    cvm.cursorIndex += 1

proc INSTFN_BAND*(cvm: var CVM, inst: Instruction) =
    ## Performs a bitwise and operation on Stack[0] using Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var toBandVal = cvm.stack[0].as_numb
    var bandUsingIndex: int
    
    if inst.operand.fromStack:
        bandUsingIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        bandUsingIndex = inst.operand.as_numb

    if bandUsingIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if bandUsingIndex < 1:
        LogError(inst.InstName & $inst.operand & " Operand can't be 0!")
        quit(-1)

    cvm.stack.PushBack(NewWord(toBandVal and cvm.stack[bandUsingIndex].as_numb))
    cvm.stack.delete(bandUsingIndex)
    cvm.stack.delete(1)

    cvm.cursorIndex += 1

proc INSTFN_BOR*(cvm: var CVM, inst: Instruction) =
    ## Performs a bitwise or operation on Stack[0] using Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var toBorVal = cvm.stack[0].as_numb
    var borUsingIndex: int
    
    if inst.operand.fromStack:
        borUsingIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        borUsingIndex = inst.operand.as_numb

    if borUsingIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if borUsingIndex < 1:
        LogError(inst.InstName & $inst.operand & " Operand can't be 0!")
        quit(-1)

    cvm.stack.PushBack(NewWord(toBorVal or cvm.stack[borUsingIndex].as_numb))
    cvm.stack.delete(borUsingIndex)
    cvm.stack.delete(1)

    cvm.cursorIndex += 1

proc INSTFN_XOR*(cvm: var CVM, inst: Instruction) =
    ## Performs xor on Stack[0] using Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var toXorVal = cvm.stack[0].as_numb
    var xorUsingIndex: int
    
    if inst.operand.fromStack:
        xorUsingIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        xorUsingIndex = inst.operand.as_numb

    if xorUsingIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if xorUsingIndex < 1:
        LogError(inst.InstName & $inst.operand & " Operand can't be 0!")
        quit(-1)

    cvm.stack.PushBack(NewWord(toXorVal xor cvm.stack[xorUsingIndex].as_numb))
    cvm.stack.delete(xorUsingIndex)
    cvm.stack.delete(1)

    cvm.cursorIndex += 1

proc INSTFN_SHL*(cvm: var CVM, inst: Instruction) =
    ## Performs shift left on Stack[0] by Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var toShlVal = cvm.stack[0].as_numb
    var shlByIndex: int
    
    if inst.operand.fromStack:
        shlByIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        shlByIndex = inst.operand.as_numb

    if shlByIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if shlByIndex < 1:
        LogError(inst.InstName & $inst.operand & " Operand can't be 0!")
        quit(-1)

    cvm.stack.PushBack(NewWord(toShlVal shl cvm.stack[shlByIndex].as_numb))
    cvm.stack.delete(shlByIndex)
    cvm.stack.delete(1)

    cvm.cursorIndex += 1

proc INSTFN_SHR*(cvm: var CVM, inst: Instruction) =
    ## Performs shift right on Stack[0] by Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var toShlVal = cvm.stack[0].as_numb
    var shlByIndex: int
    
    if inst.operand.fromStack:
        shlByIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        shlByIndex = inst.operand.as_numb

    if shlByIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if shlByIndex < 1:
        LogError(inst.InstName & $inst.operand & " Operand can't be 0!")
        quit(-1)

    cvm.stack.PushBack(NewWord(toShlVal shr cvm.stack[shlByIndex].as_numb))
    cvm.stack.delete(shlByIndex)
    cvm.stack.delete(1)

    cvm.cursorIndex += 1

proc INSTFN_AND*(cvm: var CVM, inst: Instruction) =
    ## Logic and operation on Stack[0] and Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var firstBool = cvm.stack[0].as_bool
    var secondBoolIndex: int

    if inst.operand.fromStack:
        secondBoolIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        secondBoolIndex = inst.operand.as_numb

    if secondBoolIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if secondBoolIndex < 1:
        LogError(inst.InstName & $inst.operand & " Operand can't be 0!")
        quit(-1)

    cvm.stack.PushBack(NewWord(firstBool and cvm.stack[secondBoolIndex].as_bool))
    cvm.stack.delete(secondBoolIndex)
    cvm.stack.delete(1)

    cvm.cursorIndex += 1

proc INSTFN_OR*(cvm: var CVM, inst: Instruction) =
    ## Logic or operation on Stack[0] and Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var firstBool = cvm.stack[0].as_bool
    var secondBoolIndex: int

    if inst.operand.fromStack:
        secondBoolIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        secondBoolIndex = inst.operand.as_numb

    if secondBoolIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if secondBoolIndex < 1:
        LogError(inst.InstName & $inst.operand & " Operand can't be 0!")
        quit(-1)

    cvm.stack.PushBack(NewWord(firstBool or cvm.stack[secondBoolIndex].as_bool))
    cvm.stack.delete(secondBoolIndex)
    cvm.stack.delete(1)

    cvm.cursorIndex += 1

proc INSTFN_JUMP*(cvm: var CVM, inst: Instruction) =
    ## Jumps to instruction at given operand
    if inst.operand.as_numb > cvm.program.len:
        LogError(inst.InstName & $inst.operand & " Illegal Jump Operation!")
        quit(-1)

    if inst.operand.fromStack:
        LogError("The FromStack operand is not supported for " & inst.InstName)
        quit(-1)
    
    cvm.cursorIndex = uint(inst.operand.as_numb)

proc INSTFN_JUMPC*(cvm: var CVM, inst: Instruction) =
    ## Jumps to instruction at given operand if Stack[0] == true
    if inst.operand.as_numb > cvm.program.len:
        LogError(inst.InstName & $inst.operand & " Illegal Jump Operation!")
        quit(-1)

    if inst.operand.fromStack:
        LogError("The FromStack operand is not supported for " & inst.InstName)
        quit(-1)
    
    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    if cvm.stack[0].as_bool:
        cvm.cursorIndex = uint(inst.operand.as_numb)
    else:
        cvm.cursorIndex += 1
    
    cvm.stack.delete(0)

proc INSTFN_CALL*(cvm: var CVM, inst: Instruction) =
    ## Jumps to instruction at given operand and returns on return instruction
    if inst.operand.as_numb > cvm.program.len:
        LogError(inst.InstName & $inst.operand & " Illegal CALL Operation!")
        quit(-1)
    
    if inst.operand.fromStack:
        LogError("The FromStack operand is not supported for " & inst.InstName)
        quit(-1)

    cvm.returnAddressStack.PushBack(uint64(cvm.cursorIndex) + 1)

    cvm.cursorIndex = uint64(inst.operand.as_numb)

proc INSTFN_RETURN*(cvm: var CVM, inst: Instruction) =
    ## Returns to last call Instruction
    if cvm.returnAddressStack.len < 1:
        LogError(inst.InstName & " No values on returnAddressStack!")
        quit(-1)

    cvm.cursorIndex = cvm.returnAddressStack[0]
    cvm.returnAddressStack.delete(0)

proc INSTFN_OUTPUT*(cvm: var CVM, inst: Instruction) =
    ## Prints Stack[Given Operand] as char to stdout
    
    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    if inst.operand.as_numb > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    var indexToPrint: int
    if inst.operand.fromStack:
        indexToPrint = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        indexToPrint = inst.operand.as_numb

    stdout.write(cvm.stack[indexToPrint].as_char)
    cvm.stack.delete(indexToPrint)

    cvm.cursorIndex += 1


var stackDumpCount = 0
proc INSTFN_DUMP*(cvm: var CVM, inst: Instruction) =
    ##   Function that dumps the stack to strout
    
    stackDumpCount += 1

    if inst.operand.fromStack:
        LogError("The FromStack operand is not supported for " & inst.InstName)
        quit(-1)

    if inst.operand.as_bool:
        echo "## STACK DUMP " & $stackDumpCount & " ##"

    for i in countup(0, cvm.stack.len - 1):
        echo $i & ": " & $cvm.stack[i]
    
    echo ""
    cvm.cursorIndex += 1
    
proc INSTFN_LEN*(cvm: var CVM, inst: Instruction) =
    cvm.stack.PushBack(NewWord(cvm.stack.len))
    cvm.cursorIndex += 1

proc INSTFN_EQUAL*(cvm: var CVM, inst: Instruction) =
    ## Logic equal operation on Stack[0] and Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var firstVal = cvm.stack[0].as_float
    var secondValIndex: int

    if inst.operand.fromStack:
        secondValIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        secondValIndex = inst.operand.as_numb

    if secondValIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if secondValIndex < 1:
        LogError(inst.InstName & $inst.operand & " Operand can't be 0!")
        quit(-1)

    cvm.stack.PushBack(NewWord(firstVal == cvm.stack[secondValIndex].as_float))
    cvm.stack.delete(secondValIndex)
    cvm.stack.delete(1)
    
    cvm.cursorIndex += 1

proc INSTFN_NOT*(cvm: var CVM, inst: Instruction) =
    ## Logic not operation on Stack[Given Operand]
    
    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var boolIndex: int

    if inst.operand.fromStack:
        boolIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        boolIndex = inst.operand.as_numb

    if boolIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if cvm.stack[boolIndex].as_bool:
        cvm.stack[boolIndex] = NewWord(false)
    else:
        cvm.stack[boolIndex] = NewWord(true)

    cvm.cursorIndex += 1

proc INSTFN_GREATER*(cvm: var CVM, inst: Instruction) =
    ## Logic greater operation on Stack[0] with Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var firstVal = cvm.stack[0].as_float
    var secondValIndex: int

    if inst.operand.fromStack:
        secondValIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        secondValIndex = inst.operand.as_numb

    if secondValIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if secondValIndex < 1:
        LogError(inst.InstName & $inst.operand & " Operand can't be 0!")
        quit(-1)

    cvm.stack.PushBack(NewWord(firstVal > cvm.stack[secondValIndex].as_float))
    cvm.stack.delete(secondValIndex)
    cvm.stack.delete(1)
    
    cvm.cursorIndex += 1

proc INSTFN_LESS*(cvm: var CVM, inst: Instruction) =
    ## Logic less operation on Stack[0] with Stack[Given Operand]

    if cvm.stack.len < 1:
        LogError(inst.InstName & $inst.operand & " Stack is empty!")
        quit(-1)

    var firstVal = cvm.stack[0].as_float
    var secondValIndex: int

    if inst.operand.fromStack:
        secondValIndex = cvm.stack[0].as_numb
        cvm.stack.delete(0)
    else:
        secondValIndex = inst.operand.as_numb

    if secondValIndex > cvm.stack.len - 1:
        LogError(inst.InstName & $inst.operand & " Operand out of stack range!")
        quit(-1)

    if secondValIndex < 1:
        LogError(inst.InstName & $inst.operand & " Operand can't be 0!")
        quit(-1)

    cvm.stack.PushBack(NewWord(firstVal < cvm.stack[secondValIndex].as_float))
    cvm.stack.delete(secondValIndex)
    cvm.stack.delete(1)
    
    cvm.cursorIndex += 1

proc INSTFN_READ*(cvm: var CVM, inst: Instruction) =
    echo "INSTFN"
proc INSTFN_WRITE*(cvm: var CVM, inst: Instruction) =
    echo "INSTFN"