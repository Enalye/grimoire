/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
import std.stdio : writeln, write;
import std.string;
import std.datetime;
import std.conv : to;

import grimoire;

version (Windows) {
    import core.sys.windows.dll;

    mixin SimpleDllMain;
}

export extern (D) void grLibrary(GrLibDefinition library) {
    library.addFunction(&_testFunc, "saucisse", [grString]);
}

private void _testFunc(GrCall call) {
    call.task.engine.print("DLL: " ~ call.getString(0));
}
