/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
import std.stdio : writeln, write;
import std.string;
import std.datetime;
import std.conv : to;
import std.path;
import std.file;

import grimoire;

void main() {
    version (Windows) {
        import core.sys.windows.windows : SetConsoleOutputCP;

        SetConsoleOutputCP(65_001);
    }
    try {
        const GrLocale locale = GrLocale.fr_FR;
        auto startTime = MonoTime.currTime();
        grLoadStdLibConstraint();

        generate(GrLocale.fr_FR);
        generate(GrLocale.en_US);

        auto elapsedTime = MonoTime.currTime() - startTime;
        writeln("Documentation générée en: \t", elapsedTime);
    }
    catch (Exception e) {
        writeln(e.msg);
        foreach (trace; e.info)
            writeln("at: ", trace);
    }
}

alias LibLoader = void function(GrLibDefinition);
void generate(GrLocale locale) {
    LibLoader[] libLoaders = [
        &grLoadStdLibSystem, &grLoadStdLibOptional, &grLoadStdLibLog,
        &grLoadStdLibList, &grLoadStdLibRange, &grLoadStdLibString,
        &grLoadStdLibChannel, &grLoadStdLibMath, &grLoadStdLibError,
        &grLoadStdLibTime, &grLoadStdLibTypecast, &grLoadStdLibPair,
        &grLoadStdLibBitmanip, &grLoadStdLibHashMap, &grLoadStdLibQueue,
        &grLoadStdLibCircularBuffer
    ];

    int i;
    foreach (libLoader; libLoaders) {
        GrDoc doc = new GrDoc(["docgen" ~ to!string(i)]);
        libLoader(doc);

        const string generatedText = doc.generate(locale);

        string fileName;
        foreach (part; doc.getModule()) {
            if (fileName.length)
                fileName ~= "_";
            fileName ~= part;
        }
        fileName ~= ".md";
        std.file.write(buildNormalizedPath("testdoc",
                to!string(locale), fileName), generatedText);
        i++;
    }
}
