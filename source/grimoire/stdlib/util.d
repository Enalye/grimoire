/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.util;

import grimoire.assembly, grimoire.compiler;

package {
    void function(GrString) _stdOut = &_defaultOutput;
}

/// Sets the output callback of print and printl primitives
void grSetOutputFunction(void function(GrString) callback) {
    if (!callback) {
        _stdOut = &_defaultOutput;
        return;
    }
    _stdOut = callback;
}

/// Gets the output callback of print and printl primitives
void function(GrString) grGetOutputFunction() {
    return _stdOut;
}

private void _defaultOutput(GrString message) {
    import std.stdio : writeln;

    writeln(message);
}
