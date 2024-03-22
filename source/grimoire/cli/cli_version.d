/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.cli.cli_version;

version (GrimoireCli)  :  //

import std.stdio;
import grimoire.cli.cli;

private enum Grimoire_Version_Display = "0.9";

void cliVersion(Cli.Result cli) {
    writeln("Grimoire version " ~ Grimoire_Version_Display);
}
