/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.runtime.event;

import grimoire.assembly;

import grimoire.compiler;

import grimoire.runtime.closure;

final class GrEvent {
    package(grimoire) {
        string name;
        GrType[] signature;
        GrInt address;
        GrClosure closure;
    }

    package(grimoire) this(string name_, GrInt address_, GrClosure closure_) {
        auto result = grUnmangleComposite(name_);
        name = result.name;
        signature = result.signature;
        address = address_;
        closure = closure_;
    }
}
