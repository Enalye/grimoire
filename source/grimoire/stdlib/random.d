module grimoire.stdlib.random;

import std.random;
import std.conv: to;
import grimoire.compiler, grimoire.runtime;


package(grimoire.stdlib)
void grLoadStdLibRandom() {
	grAddPrimitive(&_random, "random", ["max"], [grInt], [grInt]);
}

private void _random(GrCall call) {
	call.setInt(uniform(0, call.getInt("max")));
}