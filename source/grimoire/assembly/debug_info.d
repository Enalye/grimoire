module grimoire.assembly.debug_info;

import std.format;

/**
A class that contains debug information, should always be overridden
*/
public class GrDebugInfo {
    /**
    Stringify the debug information
    */
    abstract string to_string();
}

public class GrFunctionInfo : GrDebugInfo {
    public {
        /**
        Location of the function in the bytecode
        */
        uint bytecodePosition;
        /**
        Number of opcodes in the function
        */
        uint length;
        /**
        Name of the function
        */
        string functionName;
    }

    override string to_string() {
        return format("%d+%d\t%s", bytecodePosition, length, functionName);
    }
}