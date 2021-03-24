module grimoire.compiler.util;

import std.algorithm;
import std.algorithm.comparison;
import std.typetuple;

/// Search for strings that somewhat ressemble the base value
string[] findNearestStrings(string baseValue, const(string[]) ary, size_t distance = 0) {
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
