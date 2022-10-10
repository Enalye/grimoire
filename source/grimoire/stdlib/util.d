/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.util;

import grimoire.assembly, grimoire.compiler;

package {
    void function(GrStringValue) _stdOut = &_defaultOutput;
}

/// Sets the output callback of print and printl primitives
void grSetOutputFunction(void function(GrStringValue) callback) {
    if (!callback) {
        _stdOut = &_defaultOutput;
        return;
    }
    _stdOut = callback;
}

/// Gets the output callback of print and printl primitives
void function(GrStringValue) grGetOutputFunction() {
    return _stdOut;
}

private void _defaultOutput(GrStringValue message) {
    import std.stdio : writeln;

    writeln(message);
}
