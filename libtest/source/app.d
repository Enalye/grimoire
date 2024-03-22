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

export extern (D) GrLibrary grLibrary() {
    GrLibrary library = new GrLibrary(0);
    library.addModule(&_module);
    return library;
}

private void _module(GrModule mod) {
    mod.addFunction(&_testFunc, "saucisse", [grString]);
}

private void _testFunc(GrCall call) {
    call.task.engine.print("DLL: " ~ call.getString(0));
}
