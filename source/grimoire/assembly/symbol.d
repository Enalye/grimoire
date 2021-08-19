/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.assembly.symbol;

import std.format;

/// Stack trace
struct GrStackTrace {
    /// Where the error was raised inside this function
    uint pc;
    /// The name of the function
    string name;
    /// Source file from where the stack trace was generated
    string file;
    /// Position inside the source file where the error happened
    uint line;
    /// Ditto
    uint column;
}

/**
A class that contains debug information, should always be overridden
*/
abstract class GrDebugSymbol {
    /**
    Stringify the debug information
    */
    string prettify();
}

/**

*/
final class GrFunctionSymbol : GrDebugSymbol {
    public {
        /**
        Location of the function in the bytecode
        */
        uint start;
        /**
        Number of opcodes in the function
        */
        uint length;
        /**
        Name of the function
        */
        string name;
        /// File where the function is defined
        string file;
        /// Corresponding position in the source for each bytecode
        struct Position {
            /// Source coordinates
            uint line, column;
        }
        /// Ditto
        Position[] positions;
    }

    override string prettify() {
        return format("%d+%d\t%s", start, length, name);
    }
}
