/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.stdlib.time;

import std.datetime;
import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

void grLoadStdLibTime(GrLibDefinition library) {
    library.setModule(["std", "time"]);

    library.setModuleInfo(GrLocale.fr_FR, "Fonctions liées au temps.");
    library.setModuleInfo(GrLocale.en_US, "Time related functions.");

    library.setDescription(GrLocale.fr_FR, "Renvoie le temps écoulé.");
    library.setDescription(GrLocale.en_US, "Returns the elapsed time.");
    library.setParameters(GrLocale.fr_FR);
    library.setParameters(GrLocale.en_US);
    library.addFunction(&_time, "time", [], [grInt]);

    library.setDescription(GrLocale.fr_FR, "Bloque la tâche durant `x` passes.");
    library.setDescription(GrLocale.en_US, "Blocks the task during `x` passes.");
    library.setParameters(GrLocale.fr_FR, ["x"]);
    library.setParameters(GrLocale.en_US, ["x"]);
    library.addFunction(&_wait, "wait", [grInt]);

    library.setDescription(GrLocale.fr_FR, "Bloque la tâche durant `ms` millisecondes.");
    library.setDescription(GrLocale.en_US, "Blocks the task during `ms` milliseconds.");
    library.setParameters(GrLocale.fr_FR, ["ms"]);
    library.setParameters(GrLocale.en_US, ["ms"]);
    library.addFunction(&_sleep, "sleep", [grInt]);

    library.setDescription(GrLocale.fr_FR, "Convertis `s` secondes en millisecondes.");
    library.setDescription(GrLocale.en_US, "Converts `s` seconds in milliseconds.");
    library.setParameters(GrLocale.fr_FR, ["s"]);
    library.setParameters(GrLocale.en_US, ["s"]);
    library.addFunction(&_seconds_i, "seconds", [grInt], [grInt]);
    library.addFunction(&_seconds_f, "seconds", [grFloat], [grInt]);

    library.setDescription(GrLocale.fr_FR, "Convertis `m` secondes en millisecondes.");
    library.setDescription(GrLocale.en_US, "Converts `m` seconds in milliseconds.");
    library.setParameters(GrLocale.fr_FR, ["m"]);
    library.setParameters(GrLocale.en_US, ["m"]);
    library.addFunction(&_minutes_i, "minutes", [grInt], [grInt]);
    library.addFunction(&_minutes_f, "minutes", [grFloat], [grInt]);

    library.setDescription(GrLocale.fr_FR, "Convertis `h` heures en millisecondes.");
    library.setDescription(GrLocale.en_US, "Converts `h` hours in milliseconds.");
    library.setParameters(GrLocale.fr_FR, ["h"]);
    library.setParameters(GrLocale.en_US, ["h"]);
    library.addFunction(&_hours_i, "hours", [grInt], [grInt]);
    library.addFunction(&_hours_f, "hours", [grFloat], [grInt]);
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
