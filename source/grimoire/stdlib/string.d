/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.string;

import std.string;
import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

void grLoadStdLibString(GrLibDefinition library) {
    library.setModule(["std", "string"]);

    library.setModuleInfo(GrLocale.fr_FR, "Type de base.");
    library.setModuleInfo(GrLocale.en_US, "Built-in type.");

    library.setModuleDescription(GrLocale.fr_FR, "Type pouvant contenir des caractères UTF-8.");
    library.setModuleDescription(GrLocale.en_US, "Type that contains UTF-8 characters.");

    library.setDescription(GrLocale.fr_FR, "Retourne une copie d’`str`.");
    library.setDescription(GrLocale.en_US, "Returns a copy of `str`.");
    library.setParameters(GrLocale.fr_FR, ["str"]);
    library.setParameters(GrLocale.en_US, ["str"]);
    library.addFunction(&_copy, "copy", [grPure(grString)], [grString]);

    library.setDescription(GrLocale.fr_FR, "Renvoie la taille d’`str`.");
    library.setDescription(GrLocale.en_US, "Returns the size of `str`.");
    library.addFunction(&_size, "size", [grPure(grString)], [grInt]);

    library.setDescription(GrLocale.fr_FR, "Renvoie `true` si la `str` ne contient rien.");
    library.setDescription(GrLocale.en_US, "Returns `true` if `str` contains nothing.");
    library.addFunction(&_isEmpty, "isEmpty", [grPure(grString)], [grBool]);

    library.setDescription(GrLocale.fr_FR, "Vide la `str`.");
    library.setDescription(GrLocale.en_US, "Cleanup `str`.");
    library.addFunction(&_clear, "clear", [grString]);

    library.setDescription(GrLocale.fr_FR, "Ajoute `valeur` en début d’`str`.");
    library.setDescription(GrLocale.en_US, "Prepends `value` to the front of `str`.");
    library.setParameters(GrLocale.fr_FR, ["str", "valeur"]);
    library.setParameters(GrLocale.en_US, ["str", "value"]);
    library.addFunction(&_unshift, "unshift", [grString, grString]);

    library.setDescription(GrLocale.fr_FR, "Ajoute `valeur` en fin d’`str`.");
    library.setDescription(GrLocale.en_US, "Appends `value` to the back of `str`.");
    library.addFunction(&_push, "push", [grString, grString]);

    library.setDescription(GrLocale.fr_FR, "Retire le premier élément d’`str` et les retourne.
S’il n’existe pas, retourne `null(T)`.");
    library.setDescription(GrLocale.en_US, "Removes the first element of `str` and returns it.
If it doesn't exist, returns `null(T)`.");
    library.setParameters(GrLocale.fr_FR, ["str"]);
    library.setParameters(GrLocale.en_US, ["str"]);
    library.addFunction(&_shift, "shift", [grString], [grOptional(grString)]);

    library.setDescription(GrLocale.fr_FR, "Retire le dernier élément d’`str` et le retourne.
S’il n’existe pas, retourne `null(T)`.");
    library.setDescription(GrLocale.en_US, "Removes the last element of `str` and returns it.
If it doesn't exist, returns `null(T)`.");
    library.addFunction(&_pop, "pop", [grString], [grOptional(grString)]);

    library.setDescription(GrLocale.fr_FR,
        "Retire les premiers `quantité` éléments d’`str` et les retourne.");
    library.setDescription(GrLocale.en_US,
        "Removes the first `quantity` elements from `str` and returns them.");
    library.setParameters(GrLocale.fr_FR, ["str", "quantité"]);
    library.setParameters(GrLocale.en_US, ["str", "quantity"]);
    library.addFunction(&_shift1, "shift", [grString, grInt], [grString]);

    library.setDescription(GrLocale.fr_FR,
        "Retire `quantité` éléments d’`str` et les retourne.");
    library.setDescription(GrLocale.en_US,
        "Removes `quantity` elements from `str` and returns them.");
    library.addFunction(&_pop1, "pop", [grString, grInt], [grString]);

    library.setDescription(GrLocale.fr_FR, "Retourne le premier élément d’`str`.
S’il n’existe pas, retourne `null(T)`.");
    library.setDescription(GrLocale.en_US, "Returns the first element of `str`.
If it doesn't exist, returns `null(T)`.");
    library.setParameters(GrLocale.fr_FR, ["str"]);
    library.setParameters(GrLocale.en_US, ["str"]);
    library.addFunction(&_first, "first", [grPure(grString)], [
            grOptional(grString)
        ]);

    library.setDescription(GrLocale.fr_FR, "Returne le dernier élément d’`str`.
S’il n’existe pas, retourne `null(T)`.");
    library.setDescription(GrLocale.en_US, "Returns the last element of `str`.
If it doesn't exist, returns `null(T)`.");
    library.addFunction(&_last, "last", [grPure(grString)], [
            grOptional(grString)
        ]);

    library.setDescription(GrLocale.fr_FR, "Retire l’élément à l’`index` spécifié.");
    library.setDescription(GrLocale.en_US, "Removes the element at the specified `index`.");
    library.setParameters(GrLocale.fr_FR, ["str", "index"]);
    library.setParameters(GrLocale.en_US, ["str", "index"]);
    library.addFunction(&_remove, "remove", [grString, grInt]);

    library.setDescription(GrLocale.fr_FR,
        "Retire les éléments de `indexDébut` à `indexFin` inclus.");
    library.setDescription(GrLocale.en_US,
        "Removes the elements from `startIndex` to `endIndex` included.");
    library.setParameters(GrLocale.fr_FR, ["str", "indexDébut", "indexFin"]);
    library.setParameters(GrLocale.en_US, ["str", "startIndex", "endIndex"]);
    library.addFunction(&_remove2, "remove", [grString, grInt, grInt]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne une portion d’`str` de `indexDébut` jusqu’à `indexFin` inclus.");
    library.setDescription(GrLocale.en_US,
        "Returns a slice of `str` from `startIndex` to `endIndex` included.");
    library.addFunction(&_slice, "slice", [grPure(grString), grInt, grInt], [
            grString
        ]);

    library.setDescription(GrLocale.fr_FR, "Retourne l’inverse d’`str`.");
    library.setDescription(GrLocale.en_US, "Returns an inverted version of `str`.");
    library.setParameters(GrLocale.fr_FR, ["str"]);
    library.setParameters(GrLocale.en_US, ["str"]);
    library.addFunction(&_reverse, "reverse", [grPure(grString)], [grString]);

    library.setDescription(GrLocale.fr_FR, "Insère `valeur` dans la `str` à l’`index` spécifié.
Si `index` dépasse la taille d’`str`, `valeur` est ajouté en fin d’`str`.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`str`.");
    library.setDescription(GrLocale.en_US, "Insert `value` in `str` at the specified `index`.
If `index` is greater than the size of `str`, `value` is appended at the back of `str`.
If `index` is negative, `index` is calculated from the back of `str`.");
    library.setParameters(GrLocale.fr_FR, ["liste", "index", "valeur"]);
    library.setParameters(GrLocale.en_US, ["str", "index", "value"]);
    library.addFunction(&_insert, "insert", [grString, grInt, grPure(grString)]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne la première occurence de `valeur` dans `str` à partir d’`index`.
Si `valeur  n’existe pas, `null(int)` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`str`.");
    library.setDescription(GrLocale.en_US,
        "Returns the first occurence of `value` in `str`, starting from `index`.
If `value` does't exist, `null(int) is returned.
If `index` is negative, `index` is calculated from the back of `str`.");
    library.setParameters(GrLocale.fr_FR, ["str", "valeur"]);
    library.setParameters(GrLocale.en_US, ["str", "value"]);
    library.addFunction(&_indexOf, "indexOf", [
            grPure(grString), grPure(grString)
        ], [grOptional(grInt)]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne la dernière occurence de `valeur` dans `str` à partir d’`index`.
Si `valeur  n’existe pas, `null(int)` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`str`.");
    library.setDescription(GrLocale.en_US,
        "Returns the last occurence of `value` in `str`, starting from `index`.
If `value` does't exist, `null(int) is returned.
If `index` is negative, `index` is calculated from the back of `str`.");
    library.addFunction(&_lastIndexOf, "lastIndexOf", [
            grPure(grString), grPure(grString)
        ], [grOptional(grInt)]);

    library.setDescription(GrLocale.fr_FR, "Renvoie `true` si `valeur` existe dans `str`.");
    library.setDescription(GrLocale.en_US, "Returns `true` if `value` exists in `str`.");
    library.addFunction(&_contains, "contains", [
            grPure(grString), grPure(grString)
        ], [grBool]);

    library.setDescription(GrLocale.fr_FR, "Itère sur les caractères d’une chaîne.");
    library.setDescription(GrLocale.en_US, "Iterates on characters of a string.");
    GrType stringIterType = library.addNative("StringIterator");

    library.setDescription(GrLocale.fr_FR,
        "Retourne un itérateur qui parcours chaque caractère de la chaîne.");
    library.setDescription(GrLocale.en_US,
        "Returns an iterator that iterate through each character.");
    library.setParameters(GrLocale.fr_FR, ["chaîne"]);
    library.setParameters(GrLocale.en_US, ["str"]);
    library.addFunction(&_each, "each", [grString], [stringIterType]);

    library.setDescription(GrLocale.fr_FR, "Avance l’itérateur jusqu’au caractère suivant.");
    library.setDescription(GrLocale.en_US, "Advances the iterator until the next character.");
    library.setParameters(GrLocale.fr_FR, ["itérateur"]);
    library.setParameters(GrLocale.en_US, ["iterator"]);
    library.addFunction(&_next, "next", [stringIterType], [grOptional(grString)]);
}

private void _copy(GrCall call) {
    const GrStringValue value = call.getString(0);
    call.setString(value);
}

private void _size(GrCall call) {
    call.setInt(call.getList(0).size());
}

private void _isEmpty(GrCall call) {
    call.setBool(call.getString(0).isEmpty());
}

private void _clear(GrCall call) {
    GrString str = call.getString(0);
    str.clear();
}

private void _unshift(GrCall call) {
    GrString str = call.getString(0);
    str.unshift(call.getString(1));
}

private void _push(GrCall call) {
    GrString str = call.getString(0);
    str.push(call.getString(1));
}

private void _shift(GrCall call) {
    GrString str = call.getString(0);
    if (!str.size()) {
        call.setNull();
        return;
    }
    call.setString(str.shift());
}

private void _pop(GrCall call) {
    GrString str = call.getString(0);
    if (!str.size()) {
        call.setNull();
        return;
    }
    call.setString(str.pop());
}

private void _shift1(GrCall call) {
    GrString str = call.getString(0);
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    call.setString(str.shift(size));
}

private void _pop1(GrCall call) {
    GrString str = call.getString(0);
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    call.setString(str.pop(size));
}

private void _first(GrCall call) {
    GrString str = call.getString(0);
    if (!str.size()) {
        call.setNull();
        return;
    }
    call.setString(str.first());
}

private void _last(GrCall call) {
    GrString str = call.getString(0);
    if (!str.size()) {
        call.setNull();
        return;
    }
    call.setString(str.last());
}

private void _remove(GrCall call) {
    GrString str = call.getString(0);
    GrInt index = call.getInt(1);
    str.remove(index);
}

private void _remove2(GrCall call) {
    GrString str = call.getString(0);
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    str.remove(index1, index2);
}

private void _slice(GrCall call) {
    GrString str = call.getString(0);
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    call.setString(str.slice(index1, index2));
}

private void _reverse(GrCall call) {
    call.setString(call.getString(0).reverse());
}

private void _insert(GrCall call) {
    GrString str = call.getString(0);
    GrInt index = call.getInt(1);
    GrStringValue value = call.getString(2);
    str.insert(index, value);
}

private void _indexOf(GrCall call) {
    GrString str = call.getString(0);
    GrStringValue value = call.getString(1);
    const GrInt result = cast(GrInt) str.indexOf(value);
    if (result < 0) {
        call.setNull();
        return;
    }
    call.setInt(result);
}

private void _lastIndexOf(GrCall call) {
    GrString str = call.getString(0);
    GrStringValue value = call.getString(1);
    const GrInt result = cast(GrInt) str.lastIndexOf(value);
    if (result < 0) {
        call.setNull();
        return;
    }
    call.setInt(result);
}

private void _contains(GrCall call) {
    GrString str = call.getString(0);
    GrStringValue value = call.getString(1);
    call.setBool(str.contains(value));
}

private final class StringIterator {
    GrStringValue value;
    size_t index;
}

private void _each(GrCall call) {
    StringIterator iter = new StringIterator;
    iter.value = call.getString(0);
    call.setNative(iter);
}

private void _next(GrCall call) {
    StringIterator iter = call.getNative!(StringIterator)(0);
    if (iter.index >= iter.value.length) {
        call.setNull();
        return;
    }
    call.setString(to!GrStringValue(iter.value[iter.index]));
    iter.index++;
}
