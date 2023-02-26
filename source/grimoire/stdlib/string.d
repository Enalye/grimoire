/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.stdlib.string;

import std.string, std.utf, std.range;
import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

void grLoadStdLibString(GrLibDefinition library) {
    library.setModule(["std", "string"]);

    library.setModuleInfo(GrLocale.fr_FR, "Type de base.");
    library.setModuleInfo(GrLocale.en_US, "Built-in type.");

    library.setModuleDescription(GrLocale.fr_FR, "Type pouvant contenir des caractères UTF-8.");
    library.setModuleDescription(GrLocale.en_US, "Type that contains UTF-8 characters.");

    library.setDescription(GrLocale.fr_FR, "Retourne une copie de le chaîne.");
    library.setDescription(GrLocale.en_US, "Returns a copy of the string.");
    library.setParameters(GrLocale.fr_FR, ["self"]);
    library.setParameters(GrLocale.en_US, ["self"]);
    library.addFunction(&_copy, "copy", [grPure(grString)], [grString]);

    library.setDescription(GrLocale.fr_FR, "Renvoie la taille de la chaîne en octets.");
    library.setDescription(GrLocale.en_US, "Returns the size of the string in bytes.");
    library.addFunction(&_size, "size", [grPure(grString)], [grUInt]);

    library.setDescription(GrLocale.fr_FR, "Renvoie `true` si la chaîne est vide.");
    library.setDescription(GrLocale.en_US, "Returns `true` if the string is empty.");
    library.addFunction(&_isEmpty, "isEmpty", [grPure(grString)], [grBool]);

    library.setDescription(GrLocale.fr_FR, "Vide le contenu de la chaîne.");
    library.setDescription(GrLocale.en_US, "Clear the content of the string.");
    library.addFunction(&_clear, "clear", [grString]);

    library.setDescription(GrLocale.fr_FR, "Ajoute `str` au début de la chaîne.");
    library.setDescription(GrLocale.en_US, "Prepends `str` at the front of the string.");
    library.setParameters(GrLocale.fr_FR, ["self", "str"]);
    library.setParameters(GrLocale.en_US, ["self", "str"]);
    library.addFunction(&_pushFront, "pushFront", [grString, grString]);

    library.setDescription(GrLocale.fr_FR, "Ajoute `str` à la fin de la chaîne.");
    library.setDescription(GrLocale.en_US, "Appends `str` at the back of the string.");
    library.addFunction(&_pushBack, "pushBack", [grString, grString]);

    library.setDescription(GrLocale.fr_FR,
        "Retire le premier caractère de la chaîne et le retourne.
Retourne `null<char>` si la chaîne est vide.");
    library.setDescription(GrLocale.en_US,
        "Removes the first character of the string and returns it.
Returns `null<char>` if this string is empty.");
    library.setParameters(GrLocale.fr_FR, ["self"]);
    library.setParameters(GrLocale.en_US, ["self"]);
    library.addFunction(&_popFront, "popFront", [grString], [grOptional(grChar)]);

    library.setDescription(GrLocale.fr_FR,
        "Retire le dernier caractère de la chaîne et le retourne.
Retourne `null<char>` si la chaîne est vide.");
    library.setDescription(GrLocale.en_US,
        "Removes the last character of the string and returns it.
Returns `null<char>` if this string is empty.");
    library.addFunction(&_popBack, "popBack", [grString], [grOptional(grChar)]);

    library.setDescription(GrLocale.fr_FR,
        "Retire les X premiers caractères de la chaîne et les retourne.");
    library.setDescription(GrLocale.en_US,
        "Removes the first X characters from the string and returns them.");
    library.setParameters(GrLocale.fr_FR, ["self", "count"]);
    library.setParameters(GrLocale.en_US, ["self", "count"]);
    library.addFunction(&_popFront1, "popFront", [grString, grInt], [grString]);

    library.setDescription(GrLocale.fr_FR, "Retire N caractères de la chaîne et les retourne.");
    library.setDescription(GrLocale.en_US,
        "Removes N characters from the string and returns them.");
    library.addFunction(&_popBack1, "popBack", [grString, grInt], [grString]);

    library.setDescription(GrLocale.fr_FR, "Retourne le premier caractère de la chaîne.
Retourne `null<char>` si la chaîne est vide.");
    library.setDescription(GrLocale.en_US, "Returns the first character of the string.
Returns `null<char>` if this string is empty.");
    library.setParameters(GrLocale.fr_FR, ["self"]);
    library.setParameters(GrLocale.en_US, ["self"]);
    library.addFunction(&_front, "front", [grPure(grString)], [
            grOptional(grChar)
        ]);

    library.setDescription(GrLocale.fr_FR, "Returne le dernier élément de la chaîne.
Retourne `null<char>` si la chaîne est vide.");
    library.setDescription(GrLocale.en_US, "Returns the last element of the string.
Returns `null<char>` if this string is empty.");
    library.addFunction(&_back, "back", [grPure(grString)], [grOptional(grChar)]);

    library.setDescription(GrLocale.fr_FR, "Retire le caractère à l’index spécifié.");
    library.setDescription(GrLocale.en_US, "Removes the character at the specified index.");
    library.setParameters(GrLocale.fr_FR, ["self", "at"]);
    library.setParameters(GrLocale.en_US, ["self", "at"]);
    library.addFunction(&_remove, "remove", [grString, grInt]);

    library.setDescription(GrLocale.fr_FR, "Retire les caractères de `start` à `end` inclus.");
    library.setDescription(GrLocale.en_US,
        "Removes the characters from `start` to `end` included.");
    library.setParameters(GrLocale.fr_FR, ["self", "start", "end"]);
    library.setParameters(GrLocale.en_US, ["self", "start", "end"]);
    library.addFunction(&_remove2, "remove", [grString, grInt, grInt]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne une portion de la chaîne de `start` jusqu’à `end` inclus.");
    library.setDescription(GrLocale.en_US,
        "Returns a slice of the string from `start` to `end` included.");
    library.addFunction(&_slice, "slice", [grPure(grString), grInt, grInt], [
            grString
        ]);

    library.setDescription(GrLocale.fr_FR, "Retourne une version inversée de la chaîne.");
    library.setDescription(GrLocale.en_US, "Returns an inverted version of the string.");
    library.setParameters(GrLocale.fr_FR, ["str"]);
    library.setParameters(GrLocale.en_US, ["str"]);
    library.addFunction(&_reverse, "reverse", [grPure(grString)], [grString]);

    library.setDescription(GrLocale.fr_FR, "Insère un caractère dans la chaîne à l’index spécifié.
Si l’index dépasse la taille de la chaîne, il est ajouté à la fin.
Si l’index est négatif, il est calculé à partir de la fin.");
    library.setDescription(GrLocale.en_US,
        "Insert a character in the string at the specified index.
If the index is greater than the size of the string, it's appended at the back.
If the index is negative, the index is calculated from the back.");
    library.setParameters(GrLocale.fr_FR, ["self", "at", "ch"]);
    library.setParameters(GrLocale.en_US, ["self", "at", "ch"]);
    library.addFunction(&_insert, "insert", [grString, grInt, grPure(grString)]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne la première occurence de `str` dans la chaîne.
Si `valeur`  n’existe pas, `null<uint>` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin de la chaîne.");
    library.setDescription(GrLocale.en_US, "Returns the first occurence of `value` in the string.
If `value` does't exist, `null<uint>` is returned.
If `index` is negative, `index` is calculated from the back of the string.");
    library.setParameters(GrLocale.fr_FR, ["self", "str"]);
    library.setParameters(GrLocale.en_US, ["self", "str"]);
    library.addFunction(&_find, "find", [grPure(grString), grPure(grString)],
        [grOptional(grUInt)]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne la première occurence de `str` dans la chaîne à partir de `idx`.
Si `valeur`  n’existe pas, `null<uint>` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin de la chaîne.");
    library.setDescription(GrLocale.en_US,
        "Returns the first occurence of `value` in the string, starting from `idx`.
If `value` does't exist, `null<uint>` is returned.
If `index` is negative, `index` is calculated from the back of the string.");
    library.setParameters(GrLocale.fr_FR, ["self", "str", "idx"]);
    library.setParameters(GrLocale.en_US, ["self", "str", "idx"]);
    library.addFunction(&_find_idx, "find", [
            grPure(grString), grPure(grString), grInt
        ], [grOptional(grUInt)]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne la dernière occurence de `str` dans la chaîne.
Si `valeur`  n’existe pas, `null<uint>` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin de la chaîne.");
    library.setDescription(GrLocale.en_US, "Returns the last occurence of `str` in the string.
If `value` does't exist, `null<uint>` is returned.
If `index` is negative, `index` is calculated from the back of the string.");
    library.setParameters(GrLocale.fr_FR, ["self", "str"]);
    library.setParameters(GrLocale.en_US, ["self", "str"]);
    library.addFunction(&_rfind, "rfind", [grPure(grString),
            grPure(grString)], [grOptional(grUInt)]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne la dernière occurence de `str` dans la chaîne à partir de `idx`.
Si `valeur`  n’existe pas, `null<uint>` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin de la chaîne.");
    library.setDescription(GrLocale.en_US,
        "Returns the last occurence of `str` in the string, starting from `idx`.
If `value` does't exist, `null<uint>` is returned.
If `index` is negative, `index` is calculated from the back of the string.");
    library.setParameters(GrLocale.fr_FR, ["self", "str", "idx"]);
    library.setParameters(GrLocale.en_US, ["self", "str", "idx"]);
    library.addFunction(&_rfind_idx, "rfind", [
            grPure(grString), grPure(grString), grInt
        ], [grOptional(grUInt)]);

    library.setDescription(GrLocale.fr_FR, "Renvoie `true` si `str` existe dans la chaîne.");
    library.setDescription(GrLocale.en_US, "Returns `true` if `str` exists in the string.");
    library.addFunction(&_contains, "contains", [
            grPure(grString), grPure(grString)
        ], [grBool]);

    library.setDescription(GrLocale.fr_FR, "Itère sur chaque octet d’une chaîne.");
    library.setDescription(GrLocale.en_US, "Iterates on each byte of a string.");
    GrType bytesType = library.addNative("Bytes");

    library.setDescription(GrLocale.fr_FR,
        "Retourne un itérateur qui parcours chaque octet de la chaîne.");
    library.setDescription(GrLocale.en_US, "Returns an iterator that iterate through each byte.");
    library.setParameters(GrLocale.fr_FR, ["self"]);
    library.setParameters(GrLocale.en_US, ["self"]);
    library.addFunction(&_bytes, "bytes", [grString], [bytesType]);

    library.setDescription(GrLocale.fr_FR, "Avance l’itérateur jusqu’à l’octet suivant.");
    library.setDescription(GrLocale.en_US, "Advances the iterator until the next byte.");
    library.setParameters(GrLocale.fr_FR, ["it"]);
    library.setParameters(GrLocale.en_US, ["it"]);
    library.addFunction(&_bytes_next, "next", [bytesType], [grOptional(grInt)]); //@TODO: Changer par byte

    library.setDescription(GrLocale.fr_FR, "Itère sur les points de code d’une chaîne.");
    library.setDescription(GrLocale.en_US, "Iterates on code points of a string.");
    GrType charsType = library.addNative("Chars");

    library.setDescription(GrLocale.fr_FR,
        "Retourne un itérateur qui parcours chaque point de code.");
    library.setDescription(GrLocale.en_US,
        "Returns an iterator that iterate through each code point.");
    library.setParameters(GrLocale.fr_FR, ["chaîne"]);
    library.setParameters(GrLocale.en_US, ["str"]);
    library.addFunction(&_chars, "chars", [grString], [charsType]);

    library.setDescription(GrLocale.fr_FR, "Avance l’itérateur jusqu’au caractère suivant.");
    library.setDescription(GrLocale.en_US, "Advances the iterator until the next character.");
    library.setParameters(GrLocale.fr_FR, ["itérateur"]);
    library.setParameters(GrLocale.en_US, ["iterator"]);
    library.addFunction(&_chars_next, "next", [charsType], [grOptional(grChar)]);
}

private void _copy(GrCall call) {
    call.setString(new GrString(call.getString(0)));
}

private void _size(GrCall call) {
    call.setUInt(call.getString(0).size());
}

private void _isEmpty(GrCall call) {
    call.setBool(call.getString(0).isEmpty());
}

private void _clear(GrCall call) {
    GrString self = call.getString(0);
    self.clear();
}

private void _pushFront(GrCall call) {
    GrString self = call.getString(0);
    self.pushFront(call.getString(1));
}

private void _pushBack(GrCall call) {
    GrString self = call.getString(0);
    self.pushBack(call.getString(1));
}

private void _popFront(GrCall call) {
    GrString self = call.getString(0);

    if (self.isEmpty()) {
        call.setNull();
        return;
    }

    call.setChar(self.popFront());
}

private void _popBack(GrCall call) {
    GrString self = call.getString(0);

    if (self.isEmpty()) {
        call.setNull();
        return;
    }
    call.setChar(self.popBack());
}

private void _popFront1(GrCall call) {
    GrString self = call.getString(0);
    GrInt size = call.getInt(1);

    if (size < 0) {
        call.raise("IndexError");
        return;
    }

    call.setString(self.popFront(size));
}

private void _popBack1(GrCall call) {
    GrString self = call.getString(0);
    GrInt size = call.getInt(1);

    if (size < 0) {
        call.raise("IndexError");
        return;
    }

    call.setString(self.popBack(size));
}

private void _front(GrCall call) {
    GrString self = call.getString(0);

    if (self.isEmpty()) {
        call.setNull();
        return;
    }

    call.setChar(self.front());
}

private void _back(GrCall call) {
    GrString self = call.getString(0);

    if (self.isEmpty()) {
        call.setNull();
        return;
    }

    call.setChar(self.back());
}

private void _remove(GrCall call) {
    GrString str = call.getString(0);
    GrInt idx = call.getInt(1);

    str.remove(idx);
}

private void _remove2(GrCall call) {
    GrString str = call.getString(0);
    GrInt start = call.getInt(1);
    GrInt end = call.getInt(2);

    str.remove(start, end);
}

private void _slice(GrCall call) {
    GrString self = call.getString(0);
    GrInt start = call.getInt(1);
    GrInt end = call.getInt(2);

    call.setString(self.slice(start, end));
}

private void _reverse(GrCall call) {
    call.setString(call.getString(0).reverse());
}

private void _insert(GrCall call) {
    GrString self = call.getString(0);
    GrInt idx = call.getInt(1);
    GrString str = call.getString(2);

    self.insert(idx, str);
}

private void _find(GrCall call) {
    GrString self = call.getString(0);
    GrString str = call.getString(1);

    bool found;
    const GrUInt result = cast(GrInt) self.find(found, str);
    if (!found) {
        call.setNull();
        return;
    }

    call.setUInt(result);
}

private void _find_idx(GrCall call) {
    GrString self = call.getString(0);
    GrString str = call.getString(1);
    GrInt idx = call.getInt(2);

    bool found;
    const GrInt result = cast(GrInt) self.find(found, str, idx);
    if (!found) {
        call.setNull();
        return;
    }

    call.setUInt(result);
}

private void _rfind(GrCall call) {
    GrString self = call.getString(0);
    GrString str = call.getString(1);

    bool found;
    const GrInt result = cast(GrInt) self.rfind(found, str);
    if (result < 0) {
        call.setNull();
        return;
    }

    call.setUInt(result);
}

private void _rfind_idx(GrCall call) {
    GrString self = call.getString(0);
    GrString str = call.getString(1);

    bool found;
    const GrInt result = cast(GrInt) self.rfind(found, str);
    if (result < 0) {
        call.setNull();
        return;
    }

    call.setUInt(result);
}

private void _contains(GrCall call) {
    GrString self = call.getString(0);
    GrString str = call.getString(1);

    call.setBool(self.contains(str));
}

private final class StringIterator {
    string value;
}

private void _bytes(GrCall call) {
    StringIterator iter = new StringIterator;
    iter.value = call.getString(0).str;

    call.setNative(iter);
}

private void _bytes_next(GrCall call) {
    StringIterator iter = call.getNative!StringIterator(0);

    if (iter.value.empty) {
        call.setNull();
        return;
    }

    call.setInt(iter.value[0]);
    iter.value = iter.value[1 .. $];
}

private void _chars(GrCall call) {
    StringIterator iter = new StringIterator;
    iter.value = call.getString(0).str;

    call.setNative(iter);
}

private void _chars_next(GrCall call) {
    StringIterator iter = call.getNative!StringIterator(0);

    if (iter.value.empty) {
        call.setNull();
        return;
    }

    call.setChar(iter.value.decodeFront());
}
