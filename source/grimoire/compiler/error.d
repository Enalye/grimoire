/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.compiler.error;

import grimoire.compiler.util;

/// Contient beaucoup d’information sur l’erreur qui s’est produit
final class GrError {
    /// À quel étape l’erreur est arrivée
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
        /// À quel étape l’erreur est arrivée
        package Type type(Type type_) {
            return _type = type_;
        }
        /// Ditto
        Type type() const {
            return _type;
        }

        /// Titre de l’erreur
        package string message(string message_) {
            return _message = message_;
        }
        /// Ditto
        string message() const {
            return _message;
        }

        /// L’erreur plus en détail
        package string info(string info_) {
            return _info = info_;
        }
        /// Ditto
        string info() const {
            return _info;
        }

        /// Quelques remarques sur le problème
        package string note(string note_) {
            return _note = note_;
        }
        /// Ditto
        string note() const {
            return _note;
        }

        /// Le fichier source d’où provient le problème
        package string filePath(string filePath_) {
            return _filePath = filePath_;
        }
        /// Ditto
        string filePath() const {
            return _filePath;
        }

        /// La ligne de l’erreur dans le fichier source
        package size_t line(size_t line_) {
            return _line = line_;
        }
        /// Ditto
        size_t line() const {
            return _line;
        }

        /// La colonne de l’erreur dans le fichier source
        package size_t column(size_t column_) {
            return _column = column_;
        }
        /// Ditto
        size_t column() const {
            return _column;
        }

        /// La taille de la partie erronée. \
        /// L’erreur est situé entre `column` et `column + textLength`
        package size_t textLength(size_t textLength_) {
            return _textLength = textLength_;
        }
        /// Ditto
        size_t textLength() const {
            return _textLength;
        }

        /// La ligne entière d’où l’erreur provient
        package string lineText(string lineText_) {
            return _lineText = lineText_;
        }
        /// Ditto
        string lineText() const {
            return _lineText;
        }

        /// L’erreur plus en détail
        package string otherInfo(string otherInfo_) {
            return _otherInfo = otherInfo_;
        }
        /// Ditto
        string otherInfo() const {
            return _otherInfo;
        }

        /// Le fichier source d’où provient le problème
        package string otherFilePath(string otherFilePath_) {
            return _otherFilePath = otherFilePath_;
        }
        /// Ditto
        string otherFilePath() const {
            return _otherFilePath;
        }

        /// La ligne de l’erreur dans le fichier source
        package size_t otherLine(size_t otherLine_) {
            return _otherLine = otherLine_;
        }
        /// Ditto
        size_t otherLine() const {
            return _otherLine;
        }

        /// La colonne de l’erreur dans le fichier source
        package size_t otherColumn(size_t otherColumn_) {
            return _otherColumn = otherColumn_;
        }
        /// Ditto
        size_t otherColumn() const {
            return _otherColumn;
        }

        /// La taille de la partie erronée. \
        /// L’erreur est situé entre `column` et `column + textLength`
        package size_t otherTextLength(size_t otherTextLength_) {
            return _otherTextLength = otherTextLength_;
        }
        /// Ditto
        size_t otherTextLength() const {
            return _otherTextLength;
        }

        /// La ligne entière d’où l’erreur provient
        package string otherLineText(string otherLineText_) {
            return _otherLineText = otherLineText_;
        }
        /// Ditto
        string otherLineText() const {
            return _otherLineText;
        }
    }

    /// Formate l’erreur pour le rendre présentable
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

        // Message d’erreur
        report ~= "\033[37;1m: " ~ _message ~ "\n";

        // Informations additionnelles
        if (_otherInfo.length) {
            report ~= "\033[37;0m";

            // Chemin du fichier
            lineNumber = to!string(_otherLine) ~ "| ";
            foreach (x; 1 .. lineNumber.length)
                report ~= " ";

            report ~= "\033[1;34m->\033[0m " ~ _otherFilePath ~ "(" ~ to!string(
                _otherLine) ~ "," ~ to!string(_otherColumn) ~ ")\n";

            report ~= "\033[1;36m";

            foreach (x; 1 .. lineNumber.length)
                report ~= " ";
            report ~= "\033[1;34m|\n";

            // Aperçu du script
            report ~= " " ~ lineNumber;
            report ~= "\033[1;34m" ~ _otherLineText ~ "\033[1;34m\n";

            // Sousligner en rouge
            foreach (x; 1 .. lineNumber.length)
                report ~= " ";
            report ~= "\033[1;34m|";
            foreach (x; 0 .. _otherColumn)
                report ~= " ";

            report ~= "\033[1;36m";

            foreach (x; 0 .. _otherTextLength)
                report ~= "-";

            // Description de l’erreur
            if (_otherInfo.length)
                report ~= "  " ~ _otherInfo;
            report ~= "\n";
        }

        // Chemin du fichier
        lineNumber = to!string(_line) ~ "| ";
        foreach (x; 1 .. lineNumber.length)
            report ~= " ";

        report ~= "\033[1;34m->\033[0m " ~ _filePath ~ "(" ~ to!string(
            _line) ~ "," ~ to!string(_column) ~ ")\n";

        report ~= "\033[1;36m";

        foreach (x; 1 .. lineNumber.length)
            report ~= " ";
        report ~= "\033[1;34m|\n";

        // Aperçu du script
        report ~= " " ~ lineNumber;
        report ~= "\033[1;34m" ~ _lineText ~ "\033[1;34m\n";

        // Sousligner en rouge
        foreach (x; 1 .. lineNumber.length)
            report ~= " ";
        report ~= "\033[1;34m|";
        foreach (x; 0 .. clamp(_column, 0, _lineText.length))
            report ~= " ";

        report ~= "\033[1;31m"; // En rouge
        //report ~= "\033[1;93m"; // En orange

        foreach (x; 0 .. _textLength)
            report ~= "^";

        // Description de l’erreur
        report ~= "\033[1;31m"; // En rouge
        //report ~= "\033[0;93m"; // En orange

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
