module grimoire.lib.math.random;

import std.random;
import std.conv: to;
import grimoire.lib.api;

static this() {
	grAddPrimitive(&_random, "random", ["max"], [grInt], [grInt]);
}

private void _random(GrCall call) {
	call.setInt(uniform(0, call.getInt("max")));
}