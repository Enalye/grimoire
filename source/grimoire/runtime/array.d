/**
    Array.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.runtime.array;

import grimoire.core;
import grimoire.compiler.primitive;

import grimoire.runtime.variant;

class GrArrayValue {
	//alias ArrayStorage = IndexedArray!(GrVariantValue, 1024u);
	private GrVariantValue[] _storage;

	dstring getString(GrCall call) {
		dstring result = "["d;
        int index;
		foreach(GrVariantValue value; _storage) {
			result ~= value.getString(call);

			if((index + 1) < _storage.length)
				result ~= ", "d;
            index ++;
		}
		result ~= "]"d;
		return result;
	}

    int getLength() {
        return cast(int)_storage.length;
    }

    GrVariantValue getAt(int index) {
        return _storage[index];
    }

    int push(int ivalue) {
        GrVariantValue value;
        value.setInt(ivalue);
        auto id = cast(int)_storage.length;
        _storage ~= value;
        return id;
    }

    int push(float fvalue) {
        GrVariantValue value;
        value.setFloat(fvalue);
        auto id = cast(int)_storage.length;
        _storage ~= value;
        return id;
    }

    int push(dstring svalue) {
        GrVariantValue value;
        value.setString(svalue);
        auto id = cast(int)_storage.length;
        _storage ~= value;
        return id;
    }

    int push(GrVariantValue value) {
        auto id = cast(int)_storage.length;
        _storage ~= value;
        return id;
    }
}