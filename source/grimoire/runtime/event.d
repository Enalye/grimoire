/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */

module grimoire.runtime.event;

import grimoire.assembly;

import grimoire.compiler.type;
import grimoire.compiler.mangle;

final class GrEvent {
    package(grimoire) {
        string name;
        GrType[] signature;
        GrInt address;
    }

    package(grimoire) this(string name_, GrInt address_) {
        auto result = grUnmangleComposite(name_);
        name = result.name;
        signature = result.signature;
        address = address_;
    }
}
