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
    package {
        Type _type;
        string _message;
        string _info;
        string _filePath;
        size_t _line, _column;
        size_t _textLength;
        string _lineText;
    }

    @property {
        /// From which step the error come from.
        package Type type(Type type_) { return _type = type_; }
        /// Ditto
        Type type() const { return _type; }

        /// Error title.
        package string message(string message_) { return _message = message_; }
        /// Ditto
        string message() const { return _message; }

        /// What's wrong in details.
        package string info(string info_) { return _info = info_; }
        /// Ditto
        string info() const { return _info; }

        /// Script that generated the error.
        package string filePath(string filePath_) { return _filePath = filePath_; }
        /// Ditto
        string filePath() const { return _filePath; }

        /// Line of the error inside the script.
        package size_t line(size_t line_) { return _line = line_; }
        /// Ditto
        size_t line() const { return _line; }

        /// Character offset of the error at the line.
        package size_t column(size_t column_) { return _column = column_; }
        /// Ditto
        size_t column() const { return _column; }

        /// Size of the error segment, the error is in between `column` and `column + textLength`
        package size_t textLength(size_t textLength_) { return _textLength = textLength_; }
        /// Ditto
        size_t textLength() const { return _textLength; }

        /// The line from which the error originate
        package string lineText(string lineText_) { return _lineText = lineText_; }
        /// Ditto
        string lineText() const { return _lineText; }

    }

    /// Format the error and prints it.
    string prettify() {
        import std.conv: to;
        string report;
        
        report ~= "\033[0;91merror";
        //report ~= "\033[0;93mwarning";

        //Error report
        report ~= "\033[37;1m: " ~ _message ~ "\033[0m\n";

        //File path
        string lineNumber = to!string(_line) ~ "| ";
        foreach(x; 1 .. lineNumber.length)
            report ~= " ";

        report ~= "\033[0;36m->\033[0m "
            ~ _filePath
            ~ "(" ~ to!string(_line)
            ~ "," ~ to!string(_column)
            ~ ")\n";
        
        report ~= "\033[0;36m";

        foreach(x; 1 .. lineNumber.length)
            report ~= " ";
        report ~= "\033[0;36m|\n";

        //Script snippet
        report ~= " " ~ lineNumber;
        report ~= "\033[1;34m" ~ _lineText ~ "\033[0;36m\n";

        //Red underline
        foreach(x; 1 .. lineNumber.length)
            report ~= " ";
        report ~= "\033[0;36m|";
        foreach(x; 0 .. _column)
            report ~= " ";

        report ~= "\033[1;31m"; //Red color
        //report ~= "\033[1;93m"; //Orange color

        foreach(x; 0 .. _textLength)
            report ~= "^";
        
        //Error description
        report ~= "\033[0;31m"; //Red color
        //report ~= "\033[0;93m"; //Orange color

        if(_info.length)
            report ~= "  " ~ _info;
        report ~= "\n";

        foreach(x; 1 .. lineNumber.length)
            report ~= " ";
        report ~= "\033[0;36m|\033[0m\nCompilation aborted...";
        return report;
    }
}