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
    library.setModule("time");

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
    library.addFunction(&_wait, "wait", [grUInt]);

    GrType type;
    static foreach (T; ["Int", "UInt", "Float", "Double"]) {
        mixin("type = gr", T, ";");
        library.setDescription(GrLocale.fr_FR, "Bloque la tâche durant `ms` millisecondes.");
        library.setDescription(GrLocale.en_US, "Blocks the task during `ms` milliseconds.");
        library.setParameters(GrLocale.fr_FR, ["ms"]);
        library.setParameters(GrLocale.en_US, ["ms"]);
        library.addFunction(&_sleep!T, "sleep", [type]);

        library.setDescription(GrLocale.fr_FR, "Convertit `s` secondes en millisecondes.");
        library.setDescription(GrLocale.en_US, "Converts `s` seconds in milliseconds.");
        library.setParameters(GrLocale.fr_FR, ["s"]);
        library.setParameters(GrLocale.en_US, ["s"]);
        library.addFunction(&_seconds!T, "seconds", [type], [type]);

        library.setDescription(GrLocale.fr_FR, "Convertit `m` secondes en millisecondes.");
        library.setDescription(GrLocale.en_US, "Converts `m` seconds in milliseconds.");
        library.setParameters(GrLocale.fr_FR, ["m"]);
        library.setParameters(GrLocale.en_US, ["m"]);
        library.addFunction(&_minutes!T, "minutes", [type], [type]);

        library.setDescription(GrLocale.fr_FR, "Convertit `h` heures en millisecondes.");
        library.setDescription(GrLocale.en_US, "Converts `h` hours in milliseconds.");
        library.setParameters(GrLocale.fr_FR, ["h"]);
        library.setParameters(GrLocale.en_US, ["h"]);
        library.addFunction(&_hours!T, "hours", [type], [type]);
    }
}

private void _time(GrCall call) {
    call.setInt(cast(GrInt)(Clock.currStdTime / 10_000));
}

private void _wait(GrCall call) {
    final class WaitBlocker : GrBlocker {
        private {
            GrUInt _count;
        }

        this(GrUInt count) {
            _count = count;
        }

        override bool run() {
            if (_count <= 1)
                return true;
            _count--;
            return false;
        }
    }

    call.block(new WaitBlocker(call.getUInt(0)));
}

final class SleepBlocker(T) : GrBlocker {
    private {
        T _milliseconds;
        MonoTime _startTime;
    }

    this(T milliseconds) {
        _milliseconds = milliseconds < 0 ? 0 : milliseconds;
        _startTime = MonoTime.currTime();
    }

    override bool run() {
        return (MonoTime.currTime() - _startTime).total!"msecs" > _milliseconds;
    }
}

private void _sleep(string T)(GrCall call) {
    mixin("call.block(new SleepBlocker!(Gr", T, ")(call.get", T, "(0)));");
}

private void _seconds(string T)(GrCall call) {
    mixin("call.set", T, "(call.get", T, "(0) * 1_000);");
}

private void _minutes(string T)(GrCall call) {
    mixin("call.set", T, "(call.get", T, "(0) * 60_000);");
}

private void _hours(string T)(GrCall call) {
    mixin("call.set", T, "(call.get", T, "(0) * 3_600_000);");
}
