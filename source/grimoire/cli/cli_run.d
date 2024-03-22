/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.cli.cli_run;

version (GrimoireCli)  :  //

import std.path;
import std.stdio;
import grimoire.assembly;
import grimoire.compiler;
import grimoire.library;
import grimoire.runtime;
import grimoire.cli.cli;

void cliRun(Cli.Result cli) {
    if (cli.hasOption("help")) {
        writeln(cli.getHelp(cli.name));
        return;
    }

    string srcPath = cli.getRequiredParam(0);

    GrBytecode bytecode;

    int options;

    if (cli.hasOption("debug")) {
        options |= GrOption.symbols;
    }
    if (cli.hasOption("safe")) {
        options |= GrOption.safe;
    }
    if (cli.hasOption("profile")) {
        options |= GrOption.profile;
    }

    const GrLocale locale = GrLocale.fr_FR;
    GrLibrary stdlib = grGetStandardLibrary();

    switch (extension(srcPath)) {
    case ".gr":
        GrCompiler compiler = new GrCompiler;
        compiler.addLibrary(stdlib);
        compiler.addFile(srcPath);

        bytecode = compiler.compile(options, locale);
        if (!bytecode) {
            writeln(compiler.getError().prettify(locale));
            return;
        }
        break;
    case ".grb":
        bytecode = new GrBytecode(srcPath);
        break;
    default:
        throw new Exception("type de fichier non-reconnu `" ~ srcPath ~ "`");
    }

    GrEngine engine = new GrEngine;
    engine.addLibrary(stdlib);

    if (!engine.load(bytecode)) {
        writeln("bytecode incompatible");
        return;
    }

    engine.callEvent("app");

    while (engine.hasTasks)
        engine.process();

    if (engine.isPanicking) {
        writeln("panique: " ~ engine.panicMessage);
        foreach (trace; engine.stackTraces) {
            writeln("[", trace.pc, "] in ", trace.name, " at ", trace.file,
                "(", trace.line, ",", trace.column, ")");
        }
    }
}
