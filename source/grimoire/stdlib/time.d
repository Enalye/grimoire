module grimoire.stdlib.time;


import std.datetime;
import std.stdio: write, writeln;
import std.conv: to;
import grimoire.compiler, grimoire.runtime;


package(grimoire.stdlib)
void grLoadStdLibTime() {
	grAddPrimitive(&_clock, "clock", [], [], [grInt]);
}

private void _clock(GrCall call) {
	call.setInt(cast(int)(Clock.currStdTime / 10_000));
}