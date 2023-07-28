import strutils
import "../utility/Logger"

type Word* = object
    ## Object that holds a value that can be casted to every DataType
    as_int*: int
    as_float*: float
    as_bool*: bool
    as_char*: char
    fromStack*: bool

proc NewWord*(value: int): Word =
    ## New Word from numb
    result.as_int = value
    result.as_float = float(value)
    result.as_bool = (if value > 0: true else: false)
    
    if result.as_int > 127:
        result.as_char = char(127)
    elif result.as_int < 0:
        result.as_char = char(0)
    else:
        result.as_char = char(result.as_int)

proc NewWord*(value: float): Word =
    ## New Word from float
    result.as_int = int(value)
    result.as_float = value
    result.as_bool = (if result.as_int > 0: true else: false)

    if result.as_int > 127:
        result.as_char = char(127)
    elif result.as_int < 0:
        result.as_char = char(0)
    else:
        result.as_char = char(result.as_int)

proc NewWord*(value: bool): Word =
    ## New Word from bool
    result.as_int = int(value)
    result.as_float = float(result.as_int)
    result.as_bool = value
    result.as_char = char(result.as_int)

proc NewWord*(value: char): Word =
    ## New Word from char
    result.as_int = int(value)
    result.as_float = float(result.as_int)
    result.as_bool = (if result.as_int > 0: true else: false)
    result.as_char = value

proc NewFromStackWord*(): Word =
    # New Word from stack
    result.fromStack = true

# Type that holds an array of Words
type Stack* = seq[Word]

proc PushBack*(s: var seq, value: auto) =
    ## Function that adds a value, just like `add`, but
    ## insted of appending it adds the value at index 0 and pushes back
    ## all other values 
    s = @[value] & s

# Type that holds an array of bytes
type Memory* = seq[byte]

type DataType* = enum
    ## All nemo datatypes
    NullType,
    Numb,
    Float,
    Bool,
    Char,
    EscapedChar,

# Constant that holds all valid Escaped Chars
const EscabedChars* = @["n", "r", "t", "b", "'", "\"", "s"]


proc parseEscapedChar*(str: string): char =
    ## Parses a Escaped char contained on `str`
    var charStr = str
    charStr.removePrefix('\\')
    case charStr:
        of "n":
            result = '\n'
        of "r":
            result = '\r'
        of "t":
            result = '\t'
        of "b":
            result = '\b'
        of "'":
            result = '\''
        of "\"":
            result = '"'
        of "s":
            result = ' '
        else:
            LogError("'$#' is not a valid Escabed Char!" % (str), true)
            quit(-1)


proc DetectDataType*(str: string): DataType =
    ## Detectes the DataType of the value containes in `str`
    
    if str.endsWith('i'):
        # Checks if valid int
        try:
            var s = str
            s.removeSuffix('i')
            discard parseInt(s)
            return Numb
        except:
            LogError("'$#' is not a valid Int!" % (str), true)
            quit(-1)
    elif str.endsWith('f') and not str.startsWith("0x"):
        # Checks if valid float
        try:
            var s = str
            s.removeSuffix('f')
            discard parseFloat(s)
            return Float
        except:
            LogError("'$#' is not a valid Float!" % (str), true)
            quit(-1)
    elif str == "true" or str == "false":
        # Checks if valid bool
        return Bool
    elif str.startsWith('\'') and str.endsWith('\''):
        # Checks if valid char
        try:
            var s = str
            s.removePrefix('\'')
            s.removeSuffix('\'')

            if s.startsWith('\\') and s.len > 1:
                s.removePrefix('\\')

                # Checks if Escaped Char is valid    
                discard parseEscapedChar(s)
                return EscapedChar

            if s.len > 1:
                raise
                
            discard char(s[0])
            return Char
        except:
            LogError("$# is not a valid Char!" % (str), true)
            quit(-1)
    elif str.startsWith("0x"):
        # Checks if valid hex int
        try:
            discard parseHexInt(str)
            return Numb
        except:
            LogError("'$#' is not a valid hex Int!" % (str), true)
            quit(-1)
    else:
        return NullType