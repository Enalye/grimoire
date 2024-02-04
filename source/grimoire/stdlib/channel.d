/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.stdlib.channel;

import std.range;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

void grLoadStdLibChannel(GrLibDefinition library) {
    library.setModule("channel");

    library.setModuleInfo(GrLocale.fr_FR, "Type de base.");
    library.setModuleInfo(GrLocale.en_US, "Built-in type.");

    library.setModuleDescription(GrLocale.fr_FR,
        "Un canal est un moyen de communication et de synchronisation entre tâches.");
    library.setModuleDescription(GrLocale.en_US,
        "A channel is a messaging and synchronization tool between tasks.");

    GrType chanType = grPure(grChannel(grAny("T")));

    library.setDescription(GrLocale.fr_FR, "Retourne la taille actuelle du canal.");
    library.setDescription(GrLocale.en_US, "Returns the channel's size.");
    library.setParameters(["chan"]);
    library.addFunction(&_size, "size", [chanType], [grInt]);

    library.setDescription(GrLocale.fr_FR, "Retourne la capacité maximale du canal.");
    library.setDescription(GrLocale.en_US, "Returns the channel's capacity.");
    library.setParameters(["chan"]);
    library.addFunction(&_capacity, "capacity", [chanType], [grInt]);

    library.setDescription(GrLocale.fr_FR, "Renvoie `true` si le canal ne contient rien.");
    library.setDescription(GrLocale.en_US, "Returns `true` if the channel contains nothing.");
    library.setParameters(["chan"]);
    library.addFunction(&_isEmpty, "isEmpty", [chanType], [grBool]);

    library.setDescription(GrLocale.fr_FR,
        "Renvoie `true` si le canal a atteint sa capacité maximale.");
    library.setDescription(GrLocale.en_US,
        "Returns `true` if the channel has reached its maximum capacity.");
    library.setParameters(["chan"]);
    library.addFunction(&_isFull, "isFull", [chanType], [grBool]);
}

private void _size(GrCall call) {
    call.setInt(cast(GrInt) call.getChannel(0).size);
}

private void _capacity(GrCall call) {
    call.setInt(cast(GrInt) call.getChannel(0).capacity);
}

private void _isEmpty(GrCall call) {
    call.setBool(call.getChannel(0).isEmpty);
}

private void _isFull(GrCall call) {
    call.setBool(call.getChannel(0).isFull);
}
