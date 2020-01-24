/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.indexedarray;

import std.parallelism;
import std.range;

/**
Defragmenting array with referencable value by index.

For optimisation purposes, the index returned by the foreach statement
is the internal one : \
	- Do not attempt to use this index for anything other than calling the
	markInternalForRemoval function.
*/
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
		/// Number of items in the list.
		uint length() const { return _dataTop; }
		/// Current max.
		uint capacity() const { return _capacity; }
		/// The array itself.
		/// Avoid changing positions/size/etc.
		T[] data() { return _dataTable; }
	}

	/// Ctor
    this() {
		_dataTable.length = _capacity;
		_availableIndexes.length = _capacity;
		_translationTable.length = _capacity;
		_reverseTranslationTable.length = _capacity;
		_removeTable.length = _capacity;
    }

	/**
	Add a new item on the list.
	Returns: The index of the object.
	___
	This index will never change and will remain valid
	as long as the object is not removed from the list.
	*/
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

	/// Immediatly remove a value from the list. \
	/// Use the index returned by `push`.
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

	/// Empty the list.
	void reset() {
		_dataTop = 0u;
		_availableIndexesTop = 0u;
		_removeTop = 0u;
	}

	/// The value will be removed with the next `sweepMarkedData`. \
	/// Use the index given by the for loop.
	void markInternalForRemoval(InternalIndex index) {
		synchronized {
			_removeTable[_removeTop] = _reverseTranslationTable[index];
			_removeTop ++;
		}
	}

	/// The value will be removed with the next `sweepMarkedData`. \
	/// Use the index returned by `push`.
	void markForRemoval(uint index) {
		_removeTable[_removeTop] = index;
		_removeTop ++;
	}

	/// Marked values will be removed from the list. \
	/// Call this function **outside** of the loop that iterate over this list.
	void sweepMarkedData() {
		for(uint i = 0u; i < _removeTop; i++) {
			pop(_removeTable[i]);
		}
		_removeTop = 0u;
	}

	/// = operator
	int opApply(int delegate(ref T) dlg) {
		int result;

		foreach(i; 0u .. _dataTop) {
			result = dlg(_dataTable[i]);

			if(result)
				break;
		}

		return result;
	}

	/// Ditto
	int opApply(int delegate(const ref T) dlg) const {
		int result;

		foreach(i;  0u .. _dataTop) {
			result = dlg(_dataTable[i]);

			if(result)
				break;
		}

		return result;
	}

	/// Ditto
	int opApply(int delegate(ref T, InternalIndex) dlg) {
		int result;

		foreach(i; 0u .. _dataTop) {
			result = dlg(_dataTable[i], i);

			if(result)
				break;
		}

		return result;
	}

	/// Ditto
	int opApply(int delegate(const ref T, InternalIndex) dlg) const {
		int result;

		foreach(i; 0u .. _dataTop) {
			result = dlg(_dataTable[i], i);

			if(result)
				break;
		}

		return result;
	}

	/// [] operator
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