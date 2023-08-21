import os

#########################################################################
## Parsing
#########################################################################

# The Char used to prefix Comments
const CommentChar*: char = '#'

# The Directory path containing libs
let LibDirectory*: string = joinPath(getAppDir(), "../lib")

var VerboseOutput*: bool = false