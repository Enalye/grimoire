/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.runtime.string;

import std.string, std.utf;
import std.conv : to;
import std.algorithm : max;

import grimoire.assembly;
import grimoire.runtime.value;

/// Conteneur d’une chaîne de caractère UTF-8
final class GrString {
    private {
        GrByte[] _bytes;
    }

    alias str this;

    this() {
    }

    this(const GrString str) {
        _bytes = str._bytes.dup;
    }

    this(GrByte[] bytes_) {
        _bytes = bytes_;
    }

    this(string value) {
        this(cast(GrByte[]) value);
    }

    this(dstring value) {
        this(to!string(value));
    }

    this(GrChar[] values) {
        this(to!string(cast(dstring) values));
    }

    @property {
        pragma(inline) GrUInt size() const {
            return cast(GrUInt) _bytes.length;
        }

        pragma(inline) GrBool isEmpty() const {
            return _bytes.length == 0;
        }

        pragma(inline) GrChar[] chars() const {
            return cast(GrChar[]) to!dstring(cast(string) _bytes);
        }

        pragma(inline) string str() const {
            return cast(string) _bytes;
        }
    }

    pragma(inline) void opAssign(string values) {
        _bytes = cast(GrByte[]) values;
    }

    GrBool isCharBoundary(GrInt index) {
        if (index < 0)
            index = (cast(GrInt) _bytes.length) + index;

        if (index == 0 || index == _bytes.length)
            return true;

        if (index < 0 || index > _bytes.length)
            return false;

        return (_bytes[index] < 128 || _bytes[index] >= 192);
    }

    GrInt findCharBoundary(GrInt index) {
        if (index < 0)
            index = (cast(GrInt) _bytes.length) + index;

        if (index <= 0)
            return 0;

        if (index >= _bytes.length)
            return cast(GrInt) _bytes.length;

        while (index < _bytes.length && _bytes[index] >= 128 && _bytes[index] < 192)
            index++;

        return index;
    }

    GrInt findCharEndBoundary(GrInt index) {
        if (index < 0)
            index = (cast(GrInt) _bytes.length) + index;

        if (index >= _bytes.length)
            return cast(GrInt) _bytes.length;

        if (index <= 0)
            index = 0;

        while ((index + 1) < _bytes.length && _bytes[index + 1] >= 128 && _bytes[index + 1] < 192)
            index++;

        return index;
    }

    pragma(inline) void clear() {
        _bytes.length = 0;
    }

    pragma(inline) void resize(GrUInt size_) {
        _bytes.length = size_;
    }

    pragma(inline) GrChar front() {
        if (!_bytes.length) {
            return replacementDchar;
        }
        else if (_bytes[0] < 0x80) {
            return _bytes[0];
        }
        else {
            size_t index;
            return decode!(UseReplacementDchar.yes)(cast(string) _bytes, index);
        }
    }

    pragma(inline) GrChar back() {
        if (!_bytes.length) {
            return replacementDchar;
        }
        else if (_bytes[$ - 1] < 0x80) {
            return _bytes[$ - 1];
        }
        else {
            size_t index = _bytes.length - strideBack(cast(string) _bytes);
            return decode!(UseReplacementDchar.yes)(cast(string) _bytes, index);
        }
    }

    pragma(inline) void pushBack(GrChar ch) {
        char[4] buf;
        size_t len = encode(buf, ch);
        for (size_t i; i < len; ++i)
            _bytes ~= buf[i];
    }

    pragma(inline) void pushBack(const GrString str) {
        _bytes ~= str._bytes;
    }

    pragma(inline) GrChar popBack() {
        if (!_bytes.length) {
            return replacementDchar;
        }
        else if (_bytes[$ - 1] < 0x80) {
            immutable ch = _bytes[$ - 1];
            _bytes.length--;
            return ch;
        }
        else {
            immutable len = strideBack(cast(string) _bytes);
            size_t index = _bytes.length - len;
            immutable ch = decode!(UseReplacementDchar.yes)(cast(string) _bytes, index);
            _bytes.length -= len;
            return ch;
        }
    }

    pragma(inline) GrString popBack(GrUInt size_) {
        GrString str = new GrString;

        for (; size_ > 0; --size_) {
            if (!_bytes.length) {
                return str;
            }
            else if (_bytes[$ - 1] < 0x80) {
                immutable ch = _bytes[$ - 1];
                str._bytes = ch ~ str._bytes;
                _bytes.length--;
            }
            else {
                immutable len = strideBack(cast(string) _bytes);
                for (size_t i = cast(size_t) ((cast(long) _bytes.length) - 1); (i + len) >= _bytes.length;
                    --i)
                    str._bytes = _bytes[i] ~ str._bytes;
                _bytes.length -= len;
            }
        }

        return str;
    }

    pragma(inline) void pushFront(GrChar ch) {
        char[4] buf;
        size_t len = encode(buf, ch);
        _bytes.length += len;

        if (_bytes.length) {
            for (ptrdiff_t i = (cast(ptrdiff_t) _bytes.length) - 1; i >= len; --i)
                _bytes[i] = _bytes[i - len];
        }

        for (size_t i; i < len; ++i)
            _bytes[i] = buf[i];
    }

    pragma(inline) void pushFront(GrString value) {
        _bytes = value._bytes ~ _bytes;
    }

    pragma(inline) GrChar popFront() {
        if (!_bytes.length) {
            return replacementDchar;
        }
        else if (_bytes[0] < 0x80) {
            immutable ch = _bytes[0];
            _bytes = _bytes[1 .. $];
            return ch;
        }
        else {
            size_t len;
            immutable ch = decode!(UseReplacementDchar.yes)(cast(string) _bytes, len);
            _bytes = _bytes[len .. $];
            return ch;
        }
    }

    pragma(inline) GrString popFront(GrUInt size_) {
        GrString str = new GrString;

        for (; size_ > 0; --size_) {
            if (!_bytes.length) {
                return str;
            }
            else if (_bytes[0] < 0x80) {
                immutable ch = _bytes[0];
                str._bytes ~= ch;
                _bytes = _bytes[1 .. $];
            }
            else {
                size_t len;
                decode!(UseReplacementDchar.yes)(cast(string) _bytes, len);
                for (size_t i; i < len; ++i)
                    str._bytes ~= _bytes[i];
                _bytes = _bytes[len .. $];
            }
        }

        return str;
    }

    pragma(inline) void remove(GrInt index) {
        remove(index, index);
    }

    pragma(inline) void remove(GrInt index1, GrInt index2) {
        if (index1 < 0)
            index1 = (cast(GrInt) _bytes.length) + index1;

        if (index2 < 0)
            index2 = (cast(GrInt) _bytes.length) + index2;

        if (index2 < index1) {
            const GrInt temp = index1;
            index1 = index2;
            index2 = temp;
        }

        if (!_bytes.length || index1 >= _bytes.length || index2 < 0) {
            return;
        }

        if (index1 < 0)
            index1 = 0;

        if (index2 >= _bytes.length)
            index2 = (cast(GrInt) _bytes.length) - 1;

        index1 = findCharBoundary(index1);
        index2 = findCharEndBoundary(max(index1, index2));

        if (index1 == 0 && (index2 + 1) == _bytes.length) {
            _bytes.length = 0;
            return;
        }

        if (index1 == 0) {
            _bytes = _bytes[(index2 + 1) .. $];
            return;
        }

        if ((index2 + 1) == _bytes.length) {
            _bytes = _bytes[0 .. index1];
            return;
        }

        _bytes = _bytes[0 .. index1] ~ _bytes[(index2 + 1) .. $];
    }

    pragma(inline) GrString slice(GrInt index1, GrInt index2) {
        if (index1 < 0)
            index1 = (cast(GrInt) _bytes.length) + index1;

        if (index2 < 0)
            index2 = (cast(GrInt) _bytes.length) + index2;

        if (index2 < index1) {
            const GrInt temp = index1;
            index1 = index2;
            index2 = temp;
        }

        if (!_bytes.length || index1 >= _bytes.length || index2 < 0)
            return new GrString;

        if (index1 < 0)
            index1 = 0;

        if (index2 >= _bytes.length)
            index2 = (cast(GrInt) _bytes.length - 1);

        index1 = findCharBoundary(index1);
        index2 = findCharEndBoundary(max(index1, index2));

        if (index1 == 0 && (index2 + 1) == _bytes.length)
            return new GrString(_bytes);

        return new GrString(_bytes[index1 .. index2 + 1]);
    }

    pragma(inline) GrString reverse() {
        GrString str = new GrString;

        if (!_bytes.length) {
            return str;
        }

        for (size_t index = _bytes.length; index > 0;) {
            if (_bytes[index - 1] < 0x80) {
                str._bytes ~= _bytes[index - 1];
                index--;
            }
            else {
                immutable len = strideBack(cast(string) _bytes, index);
                index -= len;
                for (size_t i = index; i < index + len; ++i)
                    str._bytes ~= _bytes[i];
            }
        }

        return str;
    }

    pragma(inline) void insert(GrInt index, GrChar ch) {
        index = findCharBoundary(index);

        if (index >= _bytes.length) {
            pushBack(ch);
            return;
        }

        if (index <= 0) {
            pushFront(ch);
            return;
        }

        char[4] buf;
        size_t len = encode(buf, ch);
        _bytes.length += len;

        GrByte[] bytes;
        bytes.length = len;

        for (size_t i; i < len; ++i)
            bytes[i] = buf[i];

        _bytes = _bytes[0 .. index] ~ bytes ~ _bytes[index .. $];
    }

    pragma(inline) void insert(GrInt index, GrString str) {
        index = findCharBoundary(index);

        if (index >= _bytes.length) {
            _bytes ~= str._bytes;
            return;
        }

        if (index <= 0) {
            _bytes = str._bytes ~ _bytes;
            return;
        }

        _bytes = _bytes[0 .. index] ~ str._bytes ~ _bytes[index .. $];
    }

    pragma(inline) GrUInt find(ref bool found, GrString str) {
        return find(found, str, 0);
    }

    pragma(inline) GrUInt find(ref bool found, GrString str, GrInt idx) {
        idx = findCharBoundary(idx);

        immutable foundAt = (cast(string) _bytes).indexOf(cast(string) str._bytes, idx);
        if (foundAt < 0) {
            found = false;
            return 0;
        }

        found = true;
        return cast(GrUInt) foundAt;
    }

    pragma(inline) GrUInt rfind(ref bool found, GrString str) {
        return rfind(found, str, cast(GrInt) _bytes.length);
    }

    pragma(inline) GrUInt rfind(ref bool found, GrString str, GrInt idx) {
        idx = findCharBoundary(idx);

        immutable foundAt = (cast(string) _bytes).lastIndexOf(cast(string) str._bytes, idx);
        if (foundAt < 0) {
            found = false;
            return 0;
        }

        found = true;
        return cast(GrUInt) foundAt;
    }

    pragma(inline) GrBool contains(GrString str) {
        return (cast(string) _bytes).indexOf(cast(string) str._bytes) != -1;
    }
}
