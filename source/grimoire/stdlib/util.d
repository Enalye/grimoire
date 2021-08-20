/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.util;

package {
	void function(string) _stdOut = &_defaultOutput;
}

/// Sets the output of print and printl primitives
void grSetOutputFunction(void function(string) callback) {
	if (!callback) {
		_stdOut = &_defaultOutput;
		return;
	}
	_stdOut = callback;
}

private void _defaultOutput(string message) {
	import std.stdio : write;

	write(message);
}