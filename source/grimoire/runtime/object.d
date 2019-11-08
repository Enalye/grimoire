/**
Object definition.

Copyright: (c) Enalye 2019
License: Zlib
Authors: Enalye
*/

module grimoire.runtime.object;

/// A single field of an object. \
/// We can't know at runtime the type of a field,
/// so you need to check with its type definition.
package final class GrFieldValue {
    union {
        int ivalue;
        float fvalue;
        dstring svalue;
        void* ovalue;
    }
}

/// Object value in Grimoire runtime.
final class GrObjectValue {
    package {
        /// Inner fields, indexes are known at compile time.
        GrFieldValue[] fields;

        /// Ctor
        this(uint nbFields) {
            fields.length = nbFields;
            for(uint i; i < nbFields; i ++) {
                fields[i] = new GrFieldValue;
            }
        }
    }
}