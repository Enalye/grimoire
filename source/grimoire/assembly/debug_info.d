module grimoire.assembly.debug_info;

import std.format;

public class GrDebugInfo {
    string to_string() {
        return "EMPTY";
    }
}

public class GrFunctionInfo : GrDebugInfo {
    public {
        uint bytecodePosition;
        string functionName;
    }

    override string to_string() {
        return format("%d\t%s", bytecodePosition, functionName);
    }
}