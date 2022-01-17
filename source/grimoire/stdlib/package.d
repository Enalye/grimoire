/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib;

import grimoire.compiler;

public import grimoire.stdlib.util;

import grimoire.stdlib.system;
import grimoire.stdlib.list;
import grimoire.stdlib.dictionary;
import grimoire.stdlib.range;
import grimoire.stdlib.string;
import grimoire.stdlib.channel;
import grimoire.stdlib.log;
import grimoire.stdlib.math;
import grimoire.stdlib.vec2;
import grimoire.stdlib.color;
import grimoire.stdlib.test;
import grimoire.stdlib.time;
import grimoire.stdlib.typecast;
import grimoire.stdlib.pair;
import grimoire.stdlib.bitmanip;
import grimoire.stdlib.any;

/// Load the standard library
GrLibrary grLoadStdLibrary(GrLocale locale = GrLocale.en_US) {
    final switch(locale) with(GrLocale) {
    case en_US:
        _paramError = "Null parameter";
        _classError = "Unknown class";
        break;
    case fr_FR:
        _paramError = "Paramètre nul";
        _classError = "Classe inconnue";
        break;
    }

    GrLibrary library = new GrLibrary;
    grLoadStdLibLog(library, locale);
    grLoadStdLibSystem(library, locale);
    grLoadStdLibList(library, locale);
    grLoadStdLibDictionary(library, locale);
    grLoadStdLibRange(library, locale);
    grLoadStdLibString(library, locale);
    grLoadStdLibChannel(library, locale);
    grLoadStdLibMath(library, locale);
    grLoadStdLibVec2(library, locale);
    grLoadStdLibColor(library, locale);
    grLoadStdLibTest(library, locale);
    grLoadStdLibTime(library, locale);
    grLoadStdLibTypecast(library, locale);
    grLoadStdLibPair(library, locale);
    grLoadStdLibBitmanip(library, locale);
    grLoadStdLibAny(library, locale);
    return library;
}