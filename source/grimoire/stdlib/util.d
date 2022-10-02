/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.util;

import grimoire.assembly, grimoire.compiler;

package {
    void function(GrStr) _stdOut = &_defaultOutput;
}

/// Sets the output callback of print and printl primitives
void grSetOutputFunction(void function(GrStr) callback) {
    if (!callback) {
        _stdOut = &_defaultOutput;
        return;
    }
    _stdOut = callback;
}

/// Gets the output callback of print and printl primitives
void function(GrStr) grGetOutputFunction() {
    return _stdOut;
}

private void _defaultOutput(GrStr message) {
    import std.stdio : writeln;

    writeln(message);
}
