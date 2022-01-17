/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.util;

import grimoire.assembly, grimoire.compiler;

package {
    string _paramError, _classError;

    void function(GrString) _stdOut = &_defaultOutput;
    string[2][] _symbols = [
        ["any", "tout"],
        ["size", "taille"],
        ["empty?", "vide?"],
        ["full?", "plein?"],
        ["Color", "Couleur"],
        ["red", "rouge"],
        ["green", "vert"],
        ["blue", "bleu"],
        ["Pair", "Paire"],
        ["key", "clé"],
        ["value", "valeur"],
        ["Dictionary", "Dictionnaire"],
        ["IDictionary", "IDictionnaire"],
        ["IList", "IListe"],
        ["copy", "copie"],
        ["resize", "redimensionne"],
        ["fill", "remplis"],
        ["clear", "vide"],
        ["unshift", "enfile"],
        ["push", "empile"],
        ["shift", "défile"],
        ["pop", "dépile"],
        ["first", "premier"],
        ["last", "dernier"],
        ["remove", "retire"],
        ["slice", "découpe"],
        ["reverse", "inverse"],
        ["insert", "insère"],
        ["sort", "trie"],
        ["findFirst", "trouvePremier"],
        ["findLast", "trouveDernier"],
        ["has?", "a?"],
        ["each", "chaque"],
        ["next", "suivant"],
        ["print", "affiche"],
        ["clamp", "restreins"],
        ["random", "hasard"],
        ["squareRoot", "racineCarré"],
        ["floor", "arrondisInférieur"],
        ["ceil", "arrondisSupérieur"],
        ["round", "arrondis"],
        ["positive?", "positif?"],
        ["negative?", "négatif?"],
        ["zero?", "zéro?"],
        ["invalid?", "invalide?"],
        ["even?", "pair?"],
        ["odd?", "impair?"],
        ["range", "intervalle"],
        ["IRange", "IIntervalle"],
        ["IString", "IChaîne"],
        ["swap", "permute"],
        ["condition", "permute"],
        ["assert", "vérifie"],
        ["Vec2i_one", "Vec2e_un"],
        ["Vec2r_one", "Vec2r_un"],
        ["Vec2r_half", "Vec2r_moitié"],
        ["Vec2i_up", "Vec2e_haut"],
        ["Vec2r_up", "Vec2r_haut"],
        ["Vec2i_down", "Vec2e_bas"],
        ["Vec2r_down", "Vec2r_bas"],
        ["Vec2i_left", "Vec2e_gauche"],
        ["Vec2r_left", "Vec2r_gauche"],
        ["Vec2i_right", "Vec2e_droite"],
        ["Vec2r_right", "Vec2r_droite"],
        ["unpack", "sépare"],
        ["sum", "somme"],
        ["distance2", "distance2"],
        ["dot", "scalaire"],
        ["cross", "croix"],
        ["normal", "normale"],
        ["rotate!", "tourne!"],
        ["Vec2r_angled", "Vec2r_tourné"],
        ["length", "longueur"],
        ["length2", "longueur2"],
        ["normalize!", "normalise!"],
        ["normalize", "normalise"],
    ];
}

/// Experimental, may result in unwanted translations
void grTranslateStdLibrary(GrLibrary library, GrLocale targetLocale, GrLocale localeToTranslate) {
    if (localeToTranslate == targetLocale)
        return;

    foreach (ref string[2] key; _symbols) {
        library.addAlias(key[cast(int) localeToTranslate], key[cast(int) targetLocale]);
    }
}

/// Sets the output callback of print and printl primitives
void grSetOutputFunction(void function(GrString) callback) {
    if (!callback) {
        _stdOut = &_defaultOutput;
        return;
    }
    _stdOut = callback;
}

/// Gets the output callback of print and printl primitives
void function(GrString) grGetOutputFunction() {
    return _stdOut;
}

private void _defaultOutput(GrString message) {
    import std.stdio : writeln;

    writeln(message);
}
