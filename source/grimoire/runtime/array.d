/**
    Array.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.runtime.array;

import grimoire.core;
import grimoire.compiler.primitive;

import grimoire.runtime.dynamic;

class GrArrayValue {
	//alias ArrayStorage = IndexedArray!(GrDynamicValue, 1024u);
	private GrDynamicValue[] _storage;

	dstring getString(GrCall call) {
		dstring result = "["d;
        int index;
		foreach(GrDynamicValue value; _storage) {
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

    GrDynamicValue getAt(int index) {
        return _storage[index];
    }

    int push(int ivalue) {
        GrDynamicValue value;
        value.setInt(ivalue);
        auto id = cast(int)_storage.length;
        _storage ~= value;
        return id;
    }

    int push(float fvalue) {
        GrDynamicValue value;
        value.setFloat(fvalue);
        auto id = cast(int)_storage.length;
        _storage ~= value;
        return id;
    }

    int push(dstring svalue) {
        GrDynamicValue value;
        value.setString(svalue);
        auto id = cast(int)_storage.length;
        _storage ~= value;
        return id;
    }

    int push(GrDynamicValue value) {
        auto id = cast(int)_storage.length;
        _storage ~= value;
        return id;
    }
}