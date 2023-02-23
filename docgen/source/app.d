/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
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
    LibLoader[] libLoaders = grGetStdLibraryLoaders();

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
        string folderName = to!string(locale);
        auto parts = folderName.split("_");
        if (parts.length >= 1)
            folderName = parts[0];
        std.file.write(buildNormalizedPath("docs", folderName, "lib", fileName), generatedText);
        i++;
    }
}
