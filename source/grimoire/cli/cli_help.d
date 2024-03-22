/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.cli.cli_help;

version (GrimoireCli)  :  //

import std.stdio;
import grimoire.cli.cli;

void cliHelp(Cli.Result cli) {
    if (cli.optionalParamCount() >= 1)
        writeln(cli.getHelp(cli.getOptionalParam(0)));
    else
        writeln(cli.getHelp());
}
