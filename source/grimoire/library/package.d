/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.library;

import grimoire.compiler;

private {
    import grimoire.library.bitmanip;
    import grimoire.library.channel;
    import grimoire.library.circularbuffer;
    import grimoire.library.constraint;
    import grimoire.library.error;
    import grimoire.library.hashmap;
    import grimoire.library.io;
    import grimoire.library.list;
    import grimoire.library.math;
    import grimoire.library.optional;
    import grimoire.library.pair;
    import grimoire.library.queue;
    import grimoire.library.range;
    import grimoire.library.string;
    import grimoire.library.system;
    import grimoire.library.task;
    import grimoire.library.time;
    import grimoire.library.typecast;
}

private GrModuleLoader[] _libLoaders = [
    &grLoadStdLibBitmanip, &grLoadStdLibChannel, &grLoadStdLibCircularBuffer,
    &grLoadStdLibConstraint, &grLoadStdLibError, &grLoadStdLibHashMap,
    &grLoadStdLibIo, &grLoadStdLibList, &grLoadStdLibMath,
    &grLoadStdLibOptional, &grLoadStdLibPair, &grLoadStdLibQueue,
    &grLoadStdLibRange, &grLoadStdLibString, &grLoadStdLibSystem,
    &grLoadStdLibTask, &grLoadStdLibTime, &grLoadStdLibTypecast
];

GrLibrary grGetStandardLibrary() {
    GrLibrary library = new GrLibrary(9);
    foreach (GrModuleLoader loader; _libLoaders) {
        library.addModule(loader);
    }
    return library;
}
