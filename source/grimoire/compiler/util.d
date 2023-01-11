module grimoire.compiler.util;

import std.algorithm;
import std.algorithm.comparison;
import std.typetuple;

/// Options de compilation
enum GrOption {
    /// Par défaut
    none = 0x0,
    /// Génère des symboles de débogage dans le bytecode
    symbols = 0x1,
    /// Ajoute des commandes de profilage dans le bytecode
    profile = 0x2,
    /// Change certaines instructions par des versions plus sécurisés
    safe = 0x4
}

/// La langue du compilateur
enum GrLocale {
    en_US,
    fr_FR
}

/// Recherche un texte qui ressemble à peu-près à la valeur de base
package string[] findNearestStrings(const string baseValue, const(string[]) ary, size_t distance = 0) {
    struct WeightedValue {
        size_t weight;
        string value;
    }

    WeightedValue[] weightedValues;
    foreach (string value; ary) {
        size_t weight = levenshteinDistance(baseValue, value);
        if (weight > distance && distance > 0)
            continue;
        weightedValues ~= WeightedValue(weight, value);
    }
    sort!((a, b) => (a.weight < b.weight))(weightedValues);
    string[] nearestStrings;
    foreach (WeightedValue weightedValue; weightedValues) {
        nearestStrings ~= weightedValue.value;
    }
    return nearestStrings;
}
