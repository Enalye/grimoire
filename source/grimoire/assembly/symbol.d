module grimoire.assembly.symbol;

import std.format;

/// Stack trace
struct GrStackTrace {
    /// Where the error was raised inside this function
    uint pc;
    /// The name of the function
    string name;
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
    }

    override string prettify() {
        return format("%d+%d\t%s", start, length, name);
    }
}
