module grimoire.runtime.object;

import grimoire.runtime.variant;

final class GrFieldValue {
    union {
        int ivalue;
        float fvalue;
        dstring svalue;

    }
}

final class GrObjectValue {
    GrFieldValue[] fields;

    this(uint sz) {
        fields.length = sz;
        for(uint i; i < sz; i ++) {
            fields[i] = new GrFieldValue;
        }
    }
}