import strutils
include "../logging/Logger.nim"

# Object that holds a value that can be casted to every DataType
type Word = object
    as_numb: int
    as_float: float
    as_bool: bool
    as_char: char
    as_byte: byte


# New Word from numb
proc NewWord(value: int): Word =
    result.as_numb = value
    result.as_float = float(value)
    result.as_bool = (if value > 0: true else: false)
    result.as_char = char(value)
    result.as_byte = byte(value)

# New Word from float
proc NewWord(value: float): Word =
    result.as_numb = int(value)
    result.as_float = value
    result.as_bool = (if result.as_numb > 0: true else: false)
    result.as_char = char(result.as_numb)
    result.as_byte = byte(result.as_numb)

# New Word from bool
proc NewWord(value: bool): Word =
    result.as_numb = int(value)
    result.as_float = float(result.as_numb)
    result.as_bool = value
    result.as_char = char(result.as_numb)
    result.as_byte = byte(result.as_numb)

# New Word from char
proc NewWord(value: char): Word =
    result.as_numb = int(value)
    result.as_float = float(result.as_numb)
    result.as_bool = (if result.as_numb > 0: true else: false)
    result.as_char = value
    result.as_byte = byte(result.as_numb)

# New Word from byte
proc NewWord(value: byte): Word =
    result.as_numb = int(value)
    result.as_float = float(result.as_numb)
    result.as_bool = (if result.as_numb > 0: true else: false)
    result.as_char = char(result.as_numb)
    result.as_byte = value

# Type that holds a array of Words
# Size: 1024
type Stack = array[1024, Word]

# Type that holds and array of Bytes
# Size: 512 KB
type Memory = array[512000, byte]

type DataType = enum
    NullType,
    Numb,
    Float,
    Bool,
    Char,
    Byte,

proc DetectDataType(str: string): DataType =
    if str.endsWith('i'):
        try:
            var s = str
            s.removeSuffix('i')
            discard parseInt(s)
            return Numb
        except:
            LogError(str & " is not a valid Numb!")
            quit(-1)
    elif str.endsWith('f') and not str.startsWith("0x"):
        try:
            var s = str
            s.removeSuffix('f')
            discard parseFloat(s)
            return Float
        except:
            LogError(str & " is not a valid Float!")
            quit(-1)
    elif str == "true" or str == "false":
        return Bool
    elif str.startsWith('\'') and str.endsWith('\''):
        try:
            var s = str
            s.removePrefix('\'')
            s.removeSuffix('\'')
            if s.len > 1:
                raise
            discard char(s[0])
            return Char
        except:
            LogError(str & " is not a valid Char!")
            quit(-1)
    elif str.startsWith("0x"):
        try:
            discard parseHexInt(str)
            return Numb
        except:
            LogError(str & " is not a valid Numb!")
            quit(-1)
    elif str.endsWith('b'):
        try:
            var s = str
            s.removeSuffix('b')
            discard byte(parseInt(s))
            return Byte
        except:
            LogError(str & " is not a valid Byte!")
            quit(-1)
    else:
        return NullType