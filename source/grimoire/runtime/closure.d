/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.runtime.closure;

import grimoire.runtime.task;
import grimoire.runtime.value;

/// Tâche ayant accès au contexte parent. \
/// La pile locale y est référencé par copie.
final class GrClosure {
    package {
        uint pc;
        GrTask caller;
        GrValue[] locals;
    }

    package this(GrTask caller_, uint pc_) {
        pc = pc_;
        caller = caller_;

        if (caller) {
            locals = caller.locals[caller.localsPos .. caller.localsPos +
                caller.callStack[caller.stackFramePos].localStackSize].dup;
        }
    }

    package this(GrTask caller_, uint pc_, uint size) {
        pc = pc_;
        caller = caller_;

        if (caller) {
            locals = caller.locals[caller.localsPos .. caller.localsPos + size].dup;
        }
    }
}
