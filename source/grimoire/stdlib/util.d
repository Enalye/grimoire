/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.stdlib.util;

import grimoire.assembly, grimoire.compiler;

private {
    void function(string) _stdOut = &_defaultOutput;
}

/// Sets the output callback of print and printl primitives
void grSetOutputFunction(void function(string) callback) {
    if (!callback) {
        _stdOut = &_defaultOutput;
        return;
    }
    _stdOut = callback;
}

/// Gets the output callback of print and printl primitives
void function(string) grGetOutputFunction() {
    return _stdOut;
}

private void _defaultOutput(string message) {
    import std.stdio : writeln;

    writeln(message);
}

pragma(inline) void grPrint(string message) {
    _stdOut(message);
}
