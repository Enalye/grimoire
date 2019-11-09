module tester;

import std.stdio, std.file;
import std.conv: to;
import std.datetime;
import grimoire;
import scripthandler;

void testAll() {
    grInitPrimitivesDatabase();
    grInitTypesDatabase();
    grLoadStdLibrary();

    auto directories = dirEntries("", SpanMode.shallow);
    const auto startTime = MonoTime.currTime();
    uint modules;
    foreach(directory; directories) {
        if(!directory.isDir)
            continue;
        modules ++;
        writeln("\033[1;34mTesting ", directory, "\033[0m");
        testFolder(directory);
    }
    auto totalTime = MonoTime.currTime() - startTime;
    writeln("\033[1;34mTested ", modules, " in ", totalTime, "\033[0m");

    grClosePrimitivesDatabase();
    grCloseTypesDatabase();
}

private void testFolder(string dirPath) {
    auto files = dirEntries(dirPath, "{*.gr}", SpanMode.depth);
    const auto moduleStartTime = MonoTime.currTime();
    uint successes, total;
    foreach(file; files) {
        ScriptHandler handler = new ScriptHandler;
        if(!file.isFile)
            continue;
        total ++;
        string report;
        handler.load(file);

        while(handler.isRunning)
            handler.run();
        
        GrEngine engine = handler.engine;

        if(engine.isPanicking) {
            report = "\033[1;31m✘ " ~ file ~ " (" ~ to!string(engine.panicMessage) ~ ")";
        }
        else if(handler.isTimedout)
            report = "\033[1;31m✘ " ~ file ~ " (timeout)";
        else {
            report = "\033[1;32m✔ " ~ file;
            successes ++;
        }
        report ~= "\033[0m";
        writeln(report);
        handler.cleanup();
    }
    auto totalModuleTime = MonoTime.currTime() - moduleStartTime;
    writeln("\033[1;34mFinished ", dirPath, " in ", totalModuleTime, ": ", successes, "/", total, "\033[0m");
}