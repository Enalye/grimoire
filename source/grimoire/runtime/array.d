/**
    Array.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.runtime.array;

import grimoire.core;
import grimoire.compiler.primitive;

import grimoire.runtime.variant, grimoire.runtime.call;

final class GrArray {
	GrVariant[] data;

    this() {}

    this(GrArray ary) {
        foreach(ref variant; ary.data) {
            data ~= variant.copy();
        }
    }

	dstring getString(GrCall call) {
		dstring result = "["d;
        int index;
		foreach(GrVariant value; data) {
			result ~= value.getString(call);

			if((index + 1) < data.length)
				result ~= ", "d;
            index ++;
		}
		result ~= "]"d;
		return result;
	}

    int getLength() {
        return cast(int)data.length;
    }

    GrVariant getAt(int index) {
        return data[index];
    }

    int push(int ivalue) {
        GrVariant value;
        value.setInt(ivalue);
        auto id = cast(int)data.length;
        data ~= value;
        return id;
    }

    int push(float fvalue) {
        GrVariant value;
        value.setFloat(fvalue);
        auto id = cast(int)data.length;
        data ~= value;
        return id;
    }

    int push(dstring svalue) {
        GrVariant value;
        value.setString(svalue);
        auto id = cast(int)data.length;
        data ~= value;
        return id;
    }

    int push(ref GrVariant value) {
        auto id = cast(int)data.length;
        data ~= value;
        return id;
    }

    void append(ref GrVariant value) {
        data ~= value;
    }

    void prepend(ref GrVariant value) {
        data = value ~ data;
    }
}