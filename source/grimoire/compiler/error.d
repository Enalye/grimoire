/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.error;

/// Contains a lot of information about what just happened.
final class GrError {
    /// From which step the error come from.
    enum Type {
        lexer, parser
    }
    /// Ditto
    Type type;

    /// Error title.
    string message;
    /// What's wrong.
    string info;

    /// Script the generated the error.
    string filePath;
    /// Coordinates of the error inside the script.
    size_t line, column;
    /// Size of the error segment, the error is in between `column` and `column + textLength`
    size_t textLength;

    /// The line from which the error originate
    string lineText;
}