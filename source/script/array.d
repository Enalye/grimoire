/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module script.array;

import core.all;

import script.any;

class ArrayValue {
	//alias ArrayStorage = IndexedArray!(AnyValue, 1024u);
	private AnyValue[] _storage;

	dstring getString() {
		dstring result = "["d;
        int index;
		foreach(AnyValue value; _storage) {
			result ~= value.getString();

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

    AnyValue getAt(int index) {
        return _storage[index];
    }

    int push(int ivalue) {
        AnyValue value;
        value.setInteger(ivalue);
        auto id = cast(int)_storage.length;
        _storage ~= value;
        return id;
    }

    int push(float fvalue) {
        AnyValue value;
        value.setFloat(fvalue);
        auto id = cast(int)_storage.length;
        _storage ~= value;
        return id;
    }

    int push(dstring svalue) {
        AnyValue value;
        value.setString(svalue);
        auto id = cast(int)_storage.length;
        _storage ~= value;
        return id;
    }

    int push(AnyValue value) {
        auto id = cast(int)_storage.length;
        _storage ~= value;
        return id;
    }
}