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

    string folderName = to!string(locale);
    auto parts = folderName.split("_");
    if (parts.length >= 1)
        folderName = parts[0];

    string[] modules;
    int i;
    foreach (libLoader; libLoaders) {
        GrDoc doc = new GrDoc("docgen" ~ to!string(i));
        libLoader(doc);

        const string generatedText = doc.generate(locale);

        string fileName = doc.getModule() ~ ".md";
        modules ~= doc.getModule();

        std.file.write(buildNormalizedPath("docs", folderName, "lib", fileName), generatedText);
        i++;
    }

    { // Barre latérale
        string generatedText;

        string[4] categories = ["/", "/lang", "/api", "/lib"];
        string[] categoriesName;
        final switch (locale) with (GrLocale) {
        case fr_FR:
            categoriesName = [
                "Accueil", "Langage", "Intégration", "Bibliothèque standard"
            ];
            break;
        case en_US:
            categoriesName = [
                "Homepage", "Language", "Integration", "Standard library"
            ];
            break;
        }
        assert(categoriesName.length == categories.length);

        for (int t; t < 4; t++) {
            generatedText ~= "* [" ~ categoriesName[t] ~ "](/" ~ folderName ~ categories[t] ~ ")\n";
        }

        foreach (fileName; modules) {
            string line;

            line = "\t- [" ~ fileName ~ "](" ~ buildNormalizedPath("lib",
                folderName, "lib", fileName) ~ ")\n";

            generatedText ~= line;
        }
        std.file.write(buildNormalizedPath("docs", folderName, "lib",
                "_sidebar.md"), generatedText);
    }
}
