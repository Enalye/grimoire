/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.circularbuffer;

import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

void grLoadStdLibCircularBuffer(GrLibDefinition library) {
    library.setModule(["std", "circularbuffer"]);

    GrType bufType = library.addNative("CircularBuffer", ["T"]);

    library.setDescription(GrLocale.fr_FR, "Itère sur un buffer circulaire.");
    library.setDescription(GrLocale.en_US, "Iterate on a circular buffer.");
    library.addNative("CircularBufferIterator", ["T"]);

    library.addConstructor(&_new, bufType, [grInt]);

    library.setDescription(GrLocale.fr_FR, "Renvoie `true` si `buffer` ne contient rien.");
    library.setDescription(GrLocale.en_US, "Returns `true` if `buffer` contains nothing.");
    library.setParameters(GrLocale.fr_FR, ["buffer"]);
    library.setParameters(GrLocale.en_US, ["buffer"]);
    library.addFunction(&_isEmpty, "isEmpty", [grPure(bufType)], [grBool]);

    library.setDescription(GrLocale.fr_FR, "Renvoie `true` si `buffer` est plein.");
    library.setDescription(GrLocale.en_US, "Returns `true` if `buffer` is full.");
    library.addFunction(&_isFull, "isFull", [grPure(bufType)], [grBool]);

    library.setDescription(GrLocale.fr_FR, "Retourne la taille actuelle du `buffer`.");
    library.setDescription(GrLocale.en_US, "Returns the `buffer`'s size.");
    library.addFunction(&_size, "size", [grPure(bufType)], [grInt]);

    library.setDescription(GrLocale.fr_FR, "Retourne la capacité maximale du `buffer`.");
    library.setDescription(GrLocale.en_US, "Returns the `buffer`'s capacity.");
    library.addFunction(&_capacity, "capacity", [grPure(bufType)], [grInt]);

    library.setDescription(GrLocale.fr_FR, "Ajoute `valeur` dans le `buffer`.");
    library.setDescription(GrLocale.en_US, "Appends `value` to the `buffer`.");
    library.setParameters(GrLocale.fr_FR, ["buffer", "valeur"]);
    library.setParameters(GrLocale.en_US, ["buffer", "value"]);
    library.addFunction(&_push, "push", [bufType, grAny("T")]);

    library.setDescription(GrLocale.fr_FR, "Retire un élément du `buffer` et le retourne.
S’il n’en existe pas, retourne `null(T)`.");
    library.setDescription(GrLocale.en_US, "Removes an element of the `buffer` and returns it.
If there aren't any, returns `null(T)`.");
    library.setParameters(GrLocale.fr_FR, ["buffer"]);
    library.setParameters(GrLocale.en_US, ["buffer"]);
    library.addFunction(&_pop, "pop", [bufType], [grOptional(grAny("T"))]);

    library.setDescription(GrLocale.fr_FR, "Retourne le premier élément de `buffer`.
S’il n’existe pas, retourne `null(T)`.");
    library.setDescription(GrLocale.en_US, "Returns the first element of `buffer`.
If it doesn't exist, returns `null(T)`.");
    library.addFunction(&_front, "front", [grPure(bufType)], [
            grOptional(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR, "Returne le dernier élément de `buffer`.
S’il n’existe pas, retourne `null(T)`.");
    library.setDescription(GrLocale.en_US, "Returns the last element of `buffer`.
If it doesn't exist, returns `null(T)`.");
    library.addFunction(&_back, "back", [grPure(bufType)], [
            grOptional(grAny("T"))
        ]);
}

final class GrCircularBuffer {
    private {
        GrValue[] _data;
        GrInt _size, _capacity, _readIndex, _writeIndex;
    }

    @property {
        pragma(inline) GrBool isEmpty() const {
            return _size == 0;
        }

        pragma(inline) GrBool isFull() const {
            return _size == _capacity;
        }

        pragma(inline) GrInt size() const {
            return _size;
        }

        pragma(inline) GrInt capacity() const {
            return _capacity;
        }
    }

    pragma(inline) this(GrInt capacity_) {
        _capacity = capacity_ >= 1 ? capacity_ : 1;
        _data.length = _capacity;
        _writeIndex = -1;
    }

    pragma(inline) void push(GrValue value) {
        if (_size == _capacity)
            _readIndex = (_readIndex + 1) % _capacity;
        else
            _size++;

        _writeIndex = (_writeIndex + 1) % _capacity;
        _data[_writeIndex] = value;
    }

    pragma(inline) GrValue pop() {
        assert(_size > 0);
        GrValue value = _data[_readIndex];
        _readIndex = (_readIndex + 1) % _capacity;
        _size--;
        return value;
    }

    pragma(inline) GrValue front() const {
        assert(_size > 0);
        return _data[_writeIndex];
    }

    pragma(inline) GrValue back() const {
        assert(_size > 0);
        return _data[_readIndex];
    }
}

private void _new(GrCall call) {
    call.setNative(new GrCircularBuffer(call.getInt(0)));
}

private void _isEmpty(GrCall call) {
    const GrCircularBuffer buffer = call.getNative!GrCircularBuffer(0);
    call.setBool(buffer.isEmpty);
}

private void _isFull(GrCall call) {
    const GrCircularBuffer buffer = call.getNative!GrCircularBuffer(0);
    call.setBool(buffer.isFull);
}

private void _size(GrCall call) {
    const GrCircularBuffer buffer = call.getNative!GrCircularBuffer(0);
    call.setInt(buffer.size);
}

private void _capacity(GrCall call) {
    const GrCircularBuffer buffer = call.getNative!GrCircularBuffer(0);
    call.setInt(buffer.capacity);
}

private void _push(GrCall call) {
    GrCircularBuffer buffer = call.getNative!GrCircularBuffer(0);
    buffer.push(call.getValue(1));
}

private void _pop(GrCall call) {
    GrCircularBuffer buffer = call.getNative!GrCircularBuffer(0);
    if (buffer.isEmpty) {
        call.setNull();
        return;
    }
    call.setValue(buffer.pop());
}

private void _front(GrCall call) {
    GrCircularBuffer buffer = call.getNative!GrCircularBuffer(0);
    if (buffer.isEmpty) {
        call.setNull();
        return;
    }
    call.setValue(buffer.front());
}

private void _back(GrCall call) {
    GrCircularBuffer buffer = call.getNative!GrCircularBuffer(0);
    if (buffer.isEmpty) {
        call.setNull();
        return;
    }
    call.setValue(buffer.back());
}
