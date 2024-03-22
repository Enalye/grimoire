/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.cli.parser;

version (GrimoireCli)  :  //

import std.stdio;
import grimoire;
import grimoire.cli.cli;
import grimoire.cli.cli_build;
import grimoire.cli.cli_default;
import grimoire.cli.cli_help;
import grimoire.cli.cli_run;
import grimoire.cli.cli_version;

void parseArgs(string[] args) {
    Cli cli = new Cli("grimoire");

    cli.addCommand(&cliVersion, "version", "Affiche la version du programme");
    cli.addCommand(&cliHelp, "help", "Affiche l’aide", [], ["command"]);

    cli.addCommand(&cliBuild, "build", "Compile un fichier en bytecode", [
            "source"
        ]);
    cli.addCommandOption("build", "h", "help", "Affiche l’aide de la commande");
    cli.addCommandOption("build", "o", "output", "Fichier de sortie", [
            "bytecode"
        ]);
    cli.addCommandOption("build", "d", "debug", "Ajoute les symboles de déboggage");
    cli.addCommandOption("build", "s", "safe",
        "Ajoute des vérifications aux appels de fonctions");
    cli.addCommandOption("build", "p", "profile", "Ajoute des informations de profilage");

    cli.addCommand(&cliRun, "run", "Exécute un programme", ["source"]);
    cli.addCommandOption("run", "h", "help", "Affiche l’aide de la commande");
    cli.addCommandOption("run", "d", "debug", "Ajoute les symboles de déboggage");
    cli.addCommandOption("run", "s", "safe", "Ajoute des vérifications aux appels de fonctions");
    cli.addCommandOption("run", "p", "profile", "Ajoute des informations de profilage");

    cli.setDefault("run");
    cli.parse(args);
}
