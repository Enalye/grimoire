/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.error;

import grimoire.compiler.util;

/// Contains a lot of information about what just happened.
final class GrError {
    /// From which step the error come from.
    enum Type {
        lexer,
        parser
    }

    package {
        Type _type;
        string _message;
        string _info;
        string _note;
        string _filePath;
        size_t _line, _column;
        size_t _textLength;
        string _lineText;
        string _otherInfo;
        string _otherFilePath;
        size_t _otherLine, _otherColumn;
        size_t _otherTextLength;
        string _otherLineText;
    }

    @property {
        /// From which step the error come from.
        package Type type(Type type_) {
            return _type = type_;
        }
        /// Ditto
        Type type() const {
            return _type;
        }

        /// Error title.
        package string message(string message_) {
            return _message = message_;
        }
        /// Ditto
        string message() const {
            return _message;
        }

        /// What's wrong in details.
        package string info(string info_) {
            return _info = info_;
        }
        /// Ditto
        string info() const {
            return _info;
        }

        /// Some remarks about the problem.
        package string note(string note_) {
            return _note = note_;
        }
        /// Ditto
        string note() const {
            return _note;
        }

        /// Script that generated the error.
        package string filePath(string filePath_) {
            return _filePath = filePath_;
        }
        /// Ditto
        string filePath() const {
            return _filePath;
        }

        /// Line of the error inside the script.
        package size_t line(size_t line_) {
            return _line = line_;
        }
        /// Ditto
        size_t line() const {
            return _line;
        }

        /// Character offset of the error at the line.
        package size_t column(size_t column_) {
            return _column = column_;
        }
        /// Ditto
        size_t column() const {
            return _column;
        }

        /// Size of the error segment, the error is in between `column` and `column + textLength`
        package size_t textLength(size_t textLength_) {
            return _textLength = textLength_;
        }
        /// Ditto
        size_t textLength() const {
            return _textLength;
        }

        /// The line from which the error originate
        package string lineText(string lineText_) {
            return _lineText = lineText_;
        }
        /// Ditto
        string lineText() const {
            return _lineText;
        }

        /// What's wrong in details.
        package string otherInfo(string otherInfo_) {
            return _otherInfo = otherInfo_;
        }
        /// Ditto
        string otherInfo() const {
            return _otherInfo;
        }

        /// Script that generated the error.
        package string otherFilePath(string otherFilePath_) {
            return _otherFilePath = otherFilePath_;
        }
        /// Ditto
        string otherFilePath() const {
            return _otherFilePath;
        }

        /// Line of the error inside the script.
        package size_t otherLine(size_t otherLine_) {
            return _otherLine = otherLine_;
        }
        /// Ditto
        size_t otherLine() const {
            return _otherLine;
        }

        /// Character offset of the error at the line.
        package size_t otherColumn(size_t otherColumn_) {
            return _otherColumn = otherColumn_;
        }
        /// Ditto
        size_t otherColumn() const {
            return _otherColumn;
        }

        /// Size of the error segment, the error is in between `column` and `column + textLength`
        package size_t otherTextLength(size_t otherTextLength_) {
            return _otherTextLength = otherTextLength_;
        }
        /// Ditto
        size_t otherTextLength() const {
            return _otherTextLength;
        }

        /// The line from which the error originate
        package string otherLineText(string otherLineText_) {
            return _otherLineText = otherLineText_;
        }
        /// Ditto
        string otherLineText() const {
            return _otherLineText;
        }
    }

    /// Format the error and prints it.
    string prettify(GrLocale locale) {
        import std.conv : to;
        import std.algorithm.comparison : clamp;

        string report, lineNumber;

        final switch (locale) with (GrLocale) {
        case fr_FR:
            report ~= "\033[0;91merreur";
            break;
        case en_US:
            report ~= "\033[0;91merror";
            break;
        }
        //report ~= "\033[0;93mwarning";

        //Error report
        report ~= "\033[37;1m: " ~ _message ~ "\n";

        //Additional info
        if (_otherInfo.length) {
            //Error report
            report ~= "\033[37;0m";

            //File path
            lineNumber = to!string(_otherLine) ~ "| ";
            foreach (x; 1 .. lineNumber.length)
                report ~= " ";

            report ~= "\033[1;34m->\033[0m " ~ _otherFilePath ~ "(" ~ to!string(
                _otherLine) ~ "," ~ to!string(_otherColumn) ~ ")\n";

            report ~= "\033[1;36m";

            foreach (x; 1 .. lineNumber.length)
                report ~= " ";
            report ~= "\033[1;34m|\n";

            //Script snippet
            report ~= " " ~ lineNumber;
            report ~= "\033[1;34m" ~ _otherLineText ~ "\033[1;34m\n";

            //Red underline
            foreach (x; 1 .. lineNumber.length)
                report ~= " ";
            report ~= "\033[1;34m|";
            foreach (x; 0 .. _otherColumn)
                report ~= " ";

            report ~= "\033[1;36m";

            foreach (x; 0 .. _otherTextLength)
                report ~= "-";

            //Error description
            if (_otherInfo.length)
                report ~= "  " ~ _otherInfo;
            report ~= "\n";
        }

        //File path
        lineNumber = to!string(_line) ~ "| ";
        foreach (x; 1 .. lineNumber.length)
            report ~= " ";

        report ~= "\033[1;34m->\033[0m " ~ _filePath ~ "(" ~ to!string(
            _line) ~ "," ~ to!string(_column) ~ ")\n";

        report ~= "\033[1;36m";

        foreach (x; 1 .. lineNumber.length)
            report ~= " ";
        report ~= "\033[1;34m|\n";

        //Script snippet
        report ~= " " ~ lineNumber;
        report ~= "\033[1;34m" ~ _lineText ~ "\033[1;34m\n";

        //Red underline
        foreach (x; 1 .. lineNumber.length)
            report ~= " ";
        report ~= "\033[1;34m|";
        foreach (x; 0 .. clamp(_column, 0, _lineText.length))
            report ~= " ";

        report ~= "\033[1;31m"; //Red color
        //report ~= "\033[1;93m"; //Orange color

        foreach (x; 0 .. _textLength)
            report ~= "^";

        //Error description
        report ~= "\033[1;31m"; //Red color
        //report ~= "\033[0;93m"; //Orange color

        if (_info.length)
            report ~= "  " ~ _info;

        if (note.length) {
            report ~= "\n\033[1;36mnote\033[1;37m: " ~ _note ~ "\033[37;0m";
        }
        else {
            report ~= "\033[37;0m";
        }
        return report;
    }
}
