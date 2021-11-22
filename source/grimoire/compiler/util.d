module grimoire.compiler.util;

import std.algorithm;
import std.algorithm.comparison;
import std.typetuple;

/// Compiler options
enum GrOption {
    /// Default
    none = 0x0,
    /// Generate debug symbols in the bytecode
    symbols = 0x1,
    /// Add profiling commands to bytecode to fill profiling information
    profile = 0x2
}

/// Compiler locale
enum GrLocale {
    en_US,
    fr_FR
}

/// Search for strings that somewhat ressemble the base value
package string[] findNearestStrings(string baseValue, const(string[]) ary, size_t distance = 0) {
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
