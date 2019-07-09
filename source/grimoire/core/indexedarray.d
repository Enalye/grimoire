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

/*
	For optimisation purposes, the index returned by the foreach statement
	is the internal one :
		* Do not attempt to use this index for anything other than calling the
		markInternalForRemoval function.
*/

module grimoire.core.indexedarray;

import std.parallelism;
import std.range;

class DynamicIndexedArray(T) {
	alias InternalIndex = size_t;
	private {
        uint _capacity = 32u;
        uint _dataTop = 0u;
	    uint _availableIndexesTop = 0u;
	    uint _removeTop = 0u;

	    T[] _dataTable;
	    uint[] _availableIndexes;
	    uint[] _translationTable;
	    uint[] _reverseTranslationTable;
	    uint[] _removeTable;
    }

	@property {
		uint length() const { return _dataTop; }
		uint capacity() const { return _capacity; }
		T[] data() { return _dataTable; }
	}

    this() {
	    _dataTable.length = _capacity;
        _availableIndexes.length = _capacity;
	    _translationTable.length = _capacity;
	    _reverseTranslationTable.length = _capacity;
	    _removeTable.length = _capacity;
    }

	uint push(T value) {
		uint index;

		if((_dataTop + 1u) == _capacity) {
			doubleCapacity();
		}

		if(_availableIndexesTop) {
			//Take out the last available index on the list.
			_availableIndexesTop--;
			index = _availableIndexes[_availableIndexesTop];
		}
		else {
			//Or use a new id.
			index = _dataTop;
		}

		//Add the value to the data stack.
		_dataTable[_dataTop] = value;
		_translationTable[index] = _dataTop;
		_reverseTranslationTable[_dataTop] = index;

		++_dataTop;

		return index;
	}

	void pop(uint index) {
		uint valueIndex = _translationTable[index];

		//Push the index on the available indexes stack.
		_availableIndexes[_availableIndexesTop] = index;
		_availableIndexesTop++;

		//Invalidate the index.
		_translationTable[index] = -1;

		//Take the top value on the stack and fill the gap.
		_dataTop--;
		if (valueIndex < _dataTop) {
			uint userIndex = _reverseTranslationTable[_dataTop];
			_dataTable[valueIndex] = _dataTable[_dataTop];
			_translationTable[userIndex] = valueIndex;
			_reverseTranslationTable[valueIndex] = userIndex;
		}
	}

	void reset() {
		_dataTop = 0u;
		_availableIndexesTop = 0u;
		_removeTop = 0u;
	}

	void markInternalForRemoval(InternalIndex index) {
		synchronized {
			_removeTable[_removeTop] = _reverseTranslationTable[index];
			_removeTop ++;
		}
	}

	void markForRemoval(uint index) {
		_removeTable[_removeTop] = index;
		_removeTop ++;
	}


	void sweepMarkedData() {
		for(uint i = 0u; i < _removeTop; i++) {
			pop(_removeTable[i]);
		}
		_removeTop = 0u;
	}

	int opApply(int delegate(ref T) dlg) {
		int result;

		foreach(i; 0u .. _dataTop) {
			result = dlg(_dataTable[i]);

			if(result)
				break;
		}

		return result;
	}

	int opApply(int delegate(const ref T) dlg) const {
		int result;

		foreach(i;  0u .. _dataTop) {
			result = dlg(_dataTable[i]);

			if(result)
				break;
		}

		return result;
	}

	int opApply(int delegate(ref T, InternalIndex) dlg) {
		int result;

		foreach(i; 0u .. _dataTop) {
			result = dlg(_dataTable[i], i);

			if(result)
				break;
		}

		return result;
	}

	int opApply(int delegate(const ref T, InternalIndex) dlg) const {
		int result;

		foreach(i; 0u .. _dataTop) {
			result = dlg(_dataTable[i], i);

			if(result)
				break;
		}

		return result;
	}

	T opIndex(uint index) {
		return _dataTable[_translationTable[index]];
	}

    private void doubleCapacity() {
        _capacity <<= 1;
        _dataTable.length = _capacity;
        _availableIndexes.length = _capacity;
	    _translationTable.length = _capacity;
	    _reverseTranslationTable.length = _capacity;
	    _removeTable.length = _capacity;
    }
}