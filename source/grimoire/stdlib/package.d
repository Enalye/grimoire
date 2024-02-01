/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.stdlib;

import grimoire.compiler;

public {
    import grimoire.stdlib.bitmanip;
    import grimoire.stdlib.channel;
    import grimoire.stdlib.circularbuffer;
    import grimoire.stdlib.constraint;
    import grimoire.stdlib.error;
    import grimoire.stdlib.hashmap;
    import grimoire.stdlib.io;
    import grimoire.stdlib.list;
    import grimoire.stdlib.math;
    import grimoire.stdlib.optional;
    import grimoire.stdlib.pair;
    import grimoire.stdlib.queue;
    import grimoire.stdlib.range;
    import grimoire.stdlib.string;
    import grimoire.stdlib.system;
    import grimoire.stdlib.time;
    import grimoire.stdlib.typecast;
    import grimoire.stdlib.util;
}

/// Charge la bibliothèque standard
GrLibrary grLoadStdLibrary() {
    GrLibrary library = new GrLibrary;

    foreach (loader; grGetStdLibraryLoaders()) {
        loader(library);
    }

    return library;
}

/// Retourne les fonctions de chargement de la bibliothèque standard
GrLibLoader[] grGetStdLibraryLoaders() {
    return [
        &grLoadStdLibBitmanip, &grLoadStdLibChannel, &grLoadStdLibCircularBuffer,
        &grLoadStdLibConstraint, &grLoadStdLibError, &grLoadStdLibHashMap,
        &grLoadStdLibIo, &grLoadStdLibList, &grLoadStdLibMath,
        &grLoadStdLibOptional, &grLoadStdLibPair, &grLoadStdLibQueue,
        &grLoadStdLibRange, &grLoadStdLibString, &grLoadStdLibSystem,
        &grLoadStdLibTime, &grLoadStdLibTypecast
    ];
}
