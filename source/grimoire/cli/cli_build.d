/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.cli.cli_build;

version (GrimoireCli)  :  //

import std.path;
import std.stdio;
import grimoire.assembly;
import grimoire.compiler;
import grimoire.library;
import grimoire.cli.cli;

void cliBuild(Cli.Result cli) {
    if (cli.hasOption("help")) {
        writeln(cli.getHelp(cli.name));
        return;
    }

    string srcPath = cli.getRequiredParam(0);
    string appName = baseName(srcPath);
    string outPath = buildNormalizedPath(dirName(srcPath), setExtension(appName, "grb"));

    const GrLocale locale = GrLocale.fr_FR;
    GrLibrary stdlib = grGetStandardLibrary();
    GrCompiler compiler = new GrCompiler;
    compiler.addLibrary(stdlib);

    compiler.addFile(srcPath);

    GrBytecode bytecode = compiler.compile(GrOption.symbols | GrOption.safe, locale);
    if (!bytecode) {
        writeln(compiler.getError().prettify(locale));
        return;
    }
    bytecode.save(outPath);
}
