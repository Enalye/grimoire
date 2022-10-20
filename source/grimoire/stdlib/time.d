/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.time;

import std.datetime;
import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

void grLoadStdLibTime(GrLibDefinition library) {
    library.setModule(["std", "time"]);

    library.addFunction(&_time, "time", [], [grInt]);

    library.addFunction(&_wait, "wait", [grInt]);
    library.addFunction(&_sleep, "sleep", [grInt]);

    library.addFunction(&_seconds_i, "seconds", [grInt], [grInt]);
    library.addFunction(&_seconds_f, "seconds", [grReal], [grInt]);

    library.addFunction(&_minutes_i, "minutes", [grInt], [grInt]);
    library.addFunction(&_minutes_f, "minutes", [grReal], [grInt]);

    library.addFunction(&_hours_i, "hours", [grInt], [grInt]);
    library.addFunction(&_hours_f, "hours", [grReal], [grInt]);
}

private void _time(GrCall call) {
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
    call.setInt(cast(GrInt)(call.getReal(0) * 1_000f));
}

private void _minutes_i(GrCall call) {
    call.setInt(call.getInt(0) * 60_000);
}

private void _minutes_f(GrCall call) {
    call.setInt(cast(GrInt)(call.getReal(0) * 60_000f));
}

private void _hours_i(GrCall call) {
    call.setInt(call.getInt(0) * 3_600_000);
}

private void _hours_f(GrCall call) {
    call.setInt(cast(GrInt)(call.getReal(0) * 3_600_000f));
}
