module grimoire.lib.core.time;


import std.datetime;
import std.stdio: write, writeln;
import std.conv: to;
import grimoire.lib.api;

static this() {
	grAddPrimitive(&_clock, "clock", [], [], [grInt]);
}

private void _clock(GrCall call) {
	call.setInt(cast(int)(Clock.currStdTime / 10_000));
}