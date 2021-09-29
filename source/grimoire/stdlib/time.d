/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.time;

import std.datetime;
import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibTime(GrLibrary library) {
	library.addPrimitive(&_clock, "clock", [], [grInt]);

	library.addPrimitive(&_wait, "wait", [grInt]);
	library.addPrimitive(&_sleep, "sleep", [grInt]);

	library.addPrimitive(&_seconds_i, "seconds", [grInt], [grInt]);
	library.addPrimitive(&_seconds_f, "seconds", [grFloat], [grInt]);

	library.addPrimitive(&_minutes_i, "minutes", [grInt], [grInt]);
	library.addPrimitive(&_minutes_f, "minutes", [grFloat], [grInt]);

	library.addPrimitive(&_hours_i, "hours", [grInt], [grInt]);
	library.addPrimitive(&_hours_f, "hours", [grFloat], [grInt]);
}

private void _clock(GrCall call) {
	call.setInt(cast(GrInt)(Clock.currStdTime / 10_000));
}

private void _wait(GrCall call) {
	final class WaitBlocker : GrBlocker {
		private {
			GrInt _count;
		}

		this(GrInt count) {
			_count = count < 0 ? 0 : count;
		}

		override bool run() {
			if (_count <= 1)
				return true;
			_count--;
			return false;
		}
	}

	call.block(new WaitBlocker(call.getInt(0)));
}

private void _sleep(GrCall call) {
	final class SleepBlocker : GrBlocker {
		private {
			GrInt _milliseconds;
			MonoTime _startTime;
		}

		this(GrInt milliseconds) {
			_milliseconds = milliseconds < 0 ? 0 : milliseconds;
			_startTime = MonoTime.currTime();
		}

		override bool run() {
			return (MonoTime.currTime() - _startTime).total!"msecs" > _milliseconds;
		}
	}

	call.block(new SleepBlocker(call.getInt(0)));
}

private void _seconds_i(GrCall call) {
	call.setInt(call.getInt(0) * 1_000);
}

private void _seconds_f(GrCall call) {
	call.setInt(cast(GrInt)(call.getFloat(0) * 1_000f));
}

private void _minutes_i(GrCall call) {
	call.setInt(call.getInt(0) * 60_000);
}

private void _minutes_f(GrCall call) {
	call.setInt(cast(GrInt)(call.getFloat(0) * 60_000f));
}

private void _hours_i(GrCall call) {
	call.setInt(call.getInt(0) * 3_600_000);
}

private void _hours_f(GrCall call) {
	call.setInt(cast(GrInt)(call.getFloat(0) * 3_600_000f));
}
