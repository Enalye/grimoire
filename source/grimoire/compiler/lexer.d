/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.compiler.lexer;

import std.stdio, std.string, std.array, std.math, std.file;
import std.conv : to;
import std.algorithm : canFind;
import grimoire.assembly;
import grimoire.compiler.data, grimoire.compiler.error, grimoire.compiler.util;

/// Décrit la plus petite unité lexicale présent dans un fichier source
struct GrLexeme {
    /// Type de jetons valides
    enum Type {
        nothing,
        leftBracket,
        rightBracket,
        leftParenthesis,
        rightParenthesis,
        leftCurlyBrace,
        rightCurlyBrace,
        period,
        semicolon,
        colon,
        doubleColon,
        comma,
        at,
        pointer,
        optional,
        as,
        try_,
        catch_,
        throw_,
        defer,
        assign,
        bitwiseAndAssign,
        bitwiseOrAssign,
        bitwiseXorAssign,
        andAssign,
        orAssign,
        optionalOrAssign,
        addAssign,
        substractAssign,
        multiplyAssign,
        divideAssign,
        concatenateAssign,
        remainderAssign,
        powerAssign,
        plus,
        minus,
        bitwiseAnd,
        bitwiseOr,
        bitwiseXor,
        and,
        or,
        optionalOr,
        add,
        substract,
        multiply,
        divide,
        concatenate,
        remainder,
        power,
        equal,
        doubleEqual,
        threeWayComparison,
        notEqual,
        greaterOrEqual,
        greater,
        lesserOrEqual,
        lesser,
        leftShift,
        rightShift,
        interval,
        arrow,
        bitwiseNot,
        not,
        increment,
        decrement,
        identifier,
        int_,
        float_,
        bool_,
        string_,
        null_,
        public_,
        const_,
        pure_,
        alias_,
        class_,
        enum_,
        where,
        copy,
        send,
        receive,
        integerType,
        floatType,
        booleanType,
        stringType,
        listType,
        channelType,
        func,
        task,
        event,
        var,
        if_,
        unless,
        else_,
        switch_,
        select,
        case_,
        default_,
        while_,
        do_,
        until,
        for_,
        loop,
        return_,
        self,
        die,
        exit,
        yield,
        break_,
        continue_,
    }

    this(GrLexer _lexer) {
        _line = _lexer._line;
        _column = _lexer._current - _lexer._positionOfLine;
        _fileId = _lexer._fileId;
        lexer = _lexer;
    }

    private {
        /// Le lexer parent
        GrLexer lexer;

        /// L’id du fichier dans lequel il est présent
        uint _fileId;

        /// Informations sur sa position en cas d’erreur
        uint _line, _column, _textLength = 1;
    }

    @property {
        /// Sa ligne
        uint line() const {
            return _line;
        }
        /// Sa colonne
        uint column() const {
            return _column;
        }
        /// Taille du texte
        uint textLength() const {
            return _textLength;
        }
        /// Ditto
        uint textLength(uint textLength_) {
            return _textLength = textLength_;
        }
        /// L’id du fichier
        uint fileId() const {
            return _fileId;
        }
    }

    /// Type de jeton
    Type type;

    /// Est-ce que le type est une constante ?
    bool isLiteral;

    /// Est-ce que le type est une opérateur ?
    bool isOperator;

    /// Est-ce que c’est un mot-clé réservé ?
    bool isKeyword;

    /// Décrit seulement les types de premier ordre comme `int`, `string` ou `func`.
    /// Les types natifs ou les classes n’en font pas partie.
    bool isType;

    /// Valeur entière de la constante.
    /// `isLiteral` vaut `true` et `type` vaut `int_`.
    GrInt ivalue;

    /// Valeur flottante de la constante.
    /// `isLiteral` vaut `true` et `type` vaut `float_`.
    GrFloat rvalue;

    /// Valeur booléenne de la constante.
    /// `isLiteral` vaut `true` et `type` vaut `bool_`.
    GrBool bvalue;

    /// Décrit soit une valeur constante comme `"bonjour"` ou un identificateur.
    GrStringValue svalue;

    /// Renvoie la ligne entière où le jeton est situé.
    string getLine() {
        return lexer.getLine(this);
    }

    /// Renvoie le nom du fichier où le jeton est situé.
    string getFile() {
        return lexer.getFile(this);
    }
}

/// Le lexeur analyse l’entièreté du fichier et importe tous les fichiers qui y sont référencés,
/// puis génère une série de lexème qui seront analysé par le parseur.
package final class GrLexer {
    private {
        string[] _filesToImport, _filesImported;
        dstring[] _lines;
        string _file;
        dstring _text;
        uint _line, _current, _positionOfLine, _fileId;
        GrLexeme[] _lexemes;
        GrLocale _locale;
        GrData _data;
    }

    @property {
        /// Tous les jetons générés.
        GrLexeme[] lexemes() {
            return _lexemes;
        }
    }

    this(GrLocale locale) {
        _locale = locale;
    }

    /// Analyse le fichier racine et toutes ses dépendances.
    void scanFile(GrData data, string fileName) {
        import std.path : buildNormalizedPath, absolutePath;

        _data = data;

        string filePath = to!string(fileName);
        filePath = buildNormalizedPath(convertPathToImport(filePath));
        filePath = absolutePath(filePath);
        fileName = to!string(filePath);

        _filesToImport ~= fileName;

        while (_filesToImport.length) {
            _file = _filesToImport[$ - 1];
            _filesImported ~= _file;
            _text = to!dstring(readText(_file));
            _filesToImport.length--;

            _line = 0u;
            _current = 0u;
            _positionOfLine = 0u;
            _lines = split(_text, "\n");

            scanScript();

            _fileId++;
        }

        // Traduit les alias
        foreach (ref lexeme; _lexemes) {
            if (lexeme.type == GrLexeme.Type.identifier) {
                string* name = (lexeme.svalue in _data._aliases);
                if (name) {
                    lexeme.svalue = *name;
                }
            }
        }
    }

    /// Récupère toute la ligne sur lequel un lexème est présent.
    package string getLine(GrLexeme lex) {
        if (lex._fileId >= _filesImported.length)
            raiseError(Error.lexFileIdOutOfBounds);
        auto _text = to!dstring(readText(_filesImported[lex._fileId]));
        _lines = split(_text, "\n");
        if (lex._line >= _lines.length)
            raiseError(Error.lexLineCountOutOfBounds);
        return to!string(_lines[lex._line]);
    }

    /// Récupère le fichier où le lexème est présent.
    package string getFile(GrLexeme lex) {
        if (lex._fileId >= _filesImported.length)
            raiseError(Error.lexFileIdOutOfBounds);
        return _filesImported[lex._fileId];
    }
    /// Ditto
    package string getFile(size_t fileId) {
        if (fileId >= _filesImported.length)
            raiseError(Error.lexFileIdOutOfBounds);
        return _filesImported[fileId];
    }

    /// Renvoie le caractère présent à la position du curseur.
    private dchar get(int offset = 0) {
        const uint position = to!int(_current) + offset;
        if (position < 0 || position >= _text.length)
            raiseError(Error.unexpectedEndOfFile);
        return _text[position];
    }

    /// Avance le curseur tout en ignorant les espaces et les commentaires.
    private bool advance(bool startFromCurrent = false) {
        if (!startFromCurrent)
            _current++;

        if (_current >= _text.length)
            return false;

        dchar symbol = _text[_current];

        whileLoop: while (symbol <= 0x20 || symbol == '/' || symbol == '#') {
            if (_current >= _text.length)
                return false;

            symbol = _text[_current];

            if (symbol == '\n') {
                _positionOfLine = _current;
                _line++;
            }
            else if (symbol == '#') {
                do {
                    if (_current >= _text.length)
                        return false;
                    _current++;
                }
                while (_text[_current] != '\n');
                _positionOfLine = _current;
                _line++;
            }
            else if (symbol == '/') {
                if ((_current + 1) >= _text.length)
                    return false;

                switch (_text[_current + 1]) {
                case '/':
                    do {
                        if (_current >= _text.length)
                            return false;
                        _current++;
                    }
                    while (_current < _text.length && _text[_current] != '\n');
                    _positionOfLine = _current;
                    _line++;
                    break;
                case '*':
                    advance();
                    advance();
                    int commentScope = 0;
                    for (;;) {
                        if ((_current + 1) >= _text.length) {
                            _current++;
                            return false;
                        }

                        if (_text[_current] == '\n') {
                            _positionOfLine = _current;
                            _line++;
                        }
                        if (_text[_current] == '/' && _text[_current + 1] == '*') {
                            commentScope++;
                        }
                        else if (_text[_current] == '*' && _text[_current + 1] == '/') {
                            if (_current > 0 && _text[_current - 1] == '/') {
                                // On ignore
                            }
                            else if (commentScope == 0) {
                                _current++;
                                break;
                            }
                            else {
                                commentScope--;
                            }
                        }
                        _current++;
                    }
                    break;
                default:
                    break whileLoop;
                }
            }
            _current++;

            if (_current >= _text.length)
                return false;

            symbol = _text[_current];
        }
        return true;
    }

    /// Analyse le contenu d’un seul fichier
    private void scanScript() {
        // On ignore les espaces/commentaires situés au début
        advance(true);

        do {
            if (_current >= _text.length)
                break;
            switch (get()) {
            case '0': .. case '9':
                scanNumber();
                break;
            case '.':
                if (get(1) >= '0' && get(1) <= '9')
                    scanNumber();
                else
                    goto case '!';
                break;
            case '!':
            case '#': .. case '&':
            case '(': .. case '-':
            case '/':
            case ':': ..
            case '@':
            case '[': .. case '^':
            case '{': .. case '~':
                scanOperator();
                break;
            case '\"':
                scanString();
                break;
            default:
                scanWord();
                break;
            }
        }
        while (advance());
    }

    /**
	Scan either a integer or a floating point number. \
	Floats can start with a `.` \
	A number finishing with `f` will be scanned as a float. \
	Underscores `_` are ignored inside a number.
	*/
    private void scanNumber() {
        GrLexeme lex = GrLexeme(this);
        lex.isLiteral = true;

        bool isStart = true;
        bool isPrefix, isMaybeFloat, isFloat;
        bool isBinary, isOctal, isHexadecimal;
        string buffer;
        for (;;) {
            dchar symbol = get();

            if (isBinary) {
                if (symbol != '0' && symbol != '1') {
                    if (_current)
                        _current--;
                    break;
                }

                buffer ~= symbol;
            }
            else if (isOctal) {
                if (symbol < '0' || symbol > '7') {
                    if (_current)
                        _current--;
                    break;
                }

                buffer ~= symbol;
            }
            else if (isHexadecimal) {
                if (!((symbol >= '0' && symbol <= '9') || (symbol >= 'a' &&
                        symbol <= 'f') || (symbol >= 'A' && symbol <= 'F'))) {
                    if (_current)
                        _current--;
                    break;
                }

                buffer ~= symbol;
            }
            else if (isPrefix && (symbol == 'b' || symbol == 'B')) {
                isPrefix = false;
                isBinary = true;
                buffer.length = 0;
            }
            else if (isPrefix && (symbol == 'o' || symbol == 'O')) {
                isPrefix = false;
                isOctal = true;
                buffer.length = 0;
            }
            else if (isPrefix && (symbol == 'x' || symbol == 'X')) {
                isPrefix = false;
                isHexadecimal = true;
                buffer.length = 0;
            }
            else if (symbol >= '0' && symbol <= '9') {
                if (isStart && symbol == '0') {
                    isPrefix = true;
                }
                else if (isMaybeFloat) {
                    buffer ~= '.';
                    isMaybeFloat = false;
                    isFloat = true;
                }

                buffer ~= symbol;
            }
            else if (symbol == '_') {
                // On ne fait rien, c’est purement visuel (par ex: 1_000_000)
            }
            else if (symbol == '.') {
                if (isMaybeFloat) {
                    _current -= 2;
                    break;
                }
                if (isFloat) {
                    _current--;
                    break;
                }
                isMaybeFloat = true;
            }
            else if (symbol == 'f') {
                if (isMaybeFloat) {
                    _current--;
                    break;
                }
                isFloat = true;
                break;
            }
            else {
                if (_current)
                    _current--;

                if (isMaybeFloat)
                    _current--;
                break;
            }

            _current++;
            isStart = false;

            if (_current >= _text.length)
                break;
        }

        lex._textLength = cast(uint) buffer.length;

        if (!buffer.length && !isFloat) {
            lex.type = GrLexeme.Type.int_;
            lex.ivalue = 0;
            _lexemes ~= lex;
            raiseError(Error.emptyNumber);
        }

        if (isBinary) {
            lex.type = GrLexeme.Type.int_;
            lex.ivalue = to!GrInt(buffer, 2);
        }
        else if (isOctal) {
            lex.type = GrLexeme.Type.int_;
            lex.ivalue = to!GrInt(buffer, 8);
        }
        else if (isHexadecimal) {
            lex.type = GrLexeme.Type.int_;
            lex.ivalue = to!GrInt(buffer, 16);
        }
        else if (isFloat) {
            lex.type = GrLexeme.Type.float_;
            lex.rvalue = to!GrFloat(buffer);
        }
        else {
            lex.type = GrLexeme.Type.int_;
            lex.ivalue = to!GrInt(buffer);
        }
        _lexemes ~= lex;
    }

    /**
    Scan a `"` delimited string.
    */
    void scanString() {
        GrLexeme lex = GrLexeme(this);
        lex.type = GrLexeme.Type.string_;
        lex.isLiteral = true;

        if (get() != '\"')
            raiseError(Error.expectedQuotationMarkAtBeginningOfStr);
        _current++;

        string buffer;
        bool escape = false;
        bool wasEscape = false;
        for (;;) {
            if (_current >= _text.length)
                raiseError(Error.missingQuotationMarkAtEndOfStr);
            const dchar symbol = get();

            if (symbol == '\n') {
                _positionOfLine = _current;
                _line++;
            }
            else if (symbol == '\"' && (!wasEscape))
                break;
            else if (symbol == '\\' && (!wasEscape)) {
                escape = true;
            }

            if (!escape) {
                if (!wasEscape) {
                    buffer ~= symbol;
                }
                else {
                    if (symbol == 'n')
                        buffer ~= '\n';
                    else
                        buffer ~= symbol;
                }
            }
            wasEscape = escape;
            escape = false;

            _current++;
        }

        lex._textLength = cast(uint) buffer.length + 2u;
        lex.svalue = buffer;
        _lexemes ~= lex;
    }

    /**
	Scan a symbol-based operator.
	*/
    private void scanOperator() {
        GrLexeme lex = GrLexeme(this);
        lex.isOperator = true;

        switch (get()) {
        case '{':
            lex.type = GrLexeme.Type.leftCurlyBrace;
            break;
        case '}':
            lex.type = GrLexeme.Type.rightCurlyBrace;
            break;
        case '(':
            lex.type = GrLexeme.Type.leftParenthesis;
            break;
        case ')':
            lex.type = GrLexeme.Type.rightParenthesis;
            break;
        case '[':
            lex.type = GrLexeme.Type.leftBracket;
            break;
        case ']':
            lex.type = GrLexeme.Type.rightBracket;
            break;
        case '.':
            lex.type = GrLexeme.Type.period;
            break;
        case ';':
            lex.type = GrLexeme.Type.semicolon;
            break;
        case ':':
            lex.type = GrLexeme.Type.colon;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == ':') {
                lex.type = GrLexeme.Type.doubleColon;
                lex._textLength = 2;
                _current++;
            }
            break;
        case ',':
            lex.type = GrLexeme.Type.comma;
            break;
        case '@':
            lex.type = GrLexeme.Type.at;
            break;
        case '$':
            lex.type = GrLexeme.Type.pointer;
            break;
        case '&':
            lex.type = GrLexeme.Type.bitwiseAnd;
            if (_current + 1 >= _text.length)
                break;
            switch (get(1)) {
            case '=':
                lex.type = GrLexeme.Type.bitwiseAndAssign;
                lex._textLength = 2;
                _current++;
                break;
            case '&':
                lex.type = GrLexeme.Type.and;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '=') {
                    lex.type = GrLexeme.Type.andAssign;
                    lex._textLength = 3;
                    _current++;
                }
                break;
            default:
                break;
            }
            break;
        case '|':
            lex.type = GrLexeme.Type.bitwiseOr;
            if (_current + 1 >= _text.length)
                break;
            switch (get(1)) {
            case '=':
                lex.type = GrLexeme.Type.bitwiseOrAssign;
                lex._textLength = 2;
                _current++;
                break;
            case '|':
                lex.type = GrLexeme.Type.or;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '=') {
                    lex.type = GrLexeme.Type.orAssign;
                    lex._textLength = 3;
                    _current++;
                }
                break;
            default:
                break;
            }
            break;
        case '^':
            lex.type = GrLexeme.Type.bitwiseXor;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.bitwiseXorAssign;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '~':
            lex.type = GrLexeme.Type.concatenate;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.concatenateAssign;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '+':
            lex.type = GrLexeme.Type.add;
            if (_current + 1 >= _text.length)
                break;
            switch (get(1)) {
            case '=':
                lex.type = GrLexeme.Type.addAssign;
                lex._textLength = 2;
                _current++;
                break;
            case '+':
                lex.type = GrLexeme.Type.increment;
                lex._textLength = 2;
                _current++;
                break;
            default:
                break;
            }
            break;
        case '-':
            lex.type = GrLexeme.Type.substract;
            if (_current + 1 >= _text.length)
                break;
            switch (get(1)) {
            case '=':
                lex.type = GrLexeme.Type.substractAssign;
                lex._textLength = 2;
                _current++;
                break;
            case '-':
                lex.type = GrLexeme.Type.decrement;
                lex._textLength = 2;
                _current++;
                break;
            case '>':
                lex.type = GrLexeme.Type.interval;
                lex._textLength = 2;
                _current++;
                break;
            default:
                break;
            }
            break;
        case '*':
            lex.type = GrLexeme.Type.multiply;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.multiplyAssign;
                lex._textLength = 2;
                _current++;
            }
            else if (get(1) == '*') {
                lex.type = GrLexeme.Type.power;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '=') {
                    lex.type = GrLexeme.Type.powerAssign;
                    lex._textLength = 3;
                    _current++;
                }
            }
            break;
        case '/':
            lex.type = GrLexeme.Type.divide;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.divideAssign;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '%':
            lex.type = GrLexeme.Type.remainder;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.remainderAssign;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '=':
            lex.type = GrLexeme.Type.assign;
            if (_current + 1 >= _text.length)
                break;
            switch (get(1)) {
            case '=':
                lex.type = GrLexeme.Type.equal;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '=') {
                    lex.type = GrLexeme.Type.doubleEqual;
                    lex._textLength = 3;
                    _current++;
                }
                break;
            case '>':
                lex.type = GrLexeme.Type.arrow;
                lex._textLength = 2;
                _current++;
                break;
            default:
                break;
            }
            break;
        case '<':
            lex.type = GrLexeme.Type.lesser;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.lesserOrEqual;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '>') {
                    lex.type = GrLexeme.Type.threeWayComparison;
                    lex._textLength = 3;
                    _current++;
                }
            }
            else if (get(1) == '-') {
                lex.type = GrLexeme.Type.send;
                lex._textLength = 2;
                _current++;
            }
            else if (get(1) == '<') {
                lex.type = GrLexeme.Type.leftShift;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '>':
            lex.type = GrLexeme.Type.greater;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.greaterOrEqual;
                lex._textLength = 2;
                _current++;
            }
            else if (get(1) == '>') {
                lex.type = GrLexeme.Type.rightShift;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '!':
            lex.type = GrLexeme.Type.not;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '=') {
                lex.type = GrLexeme.Type.notEqual;
                lex._textLength = 2;
                _current++;
            }
            break;
        case '?':
            lex.type = GrLexeme.Type.optional;
            if (_current + 1 >= _text.length)
                break;
            if (get(1) == '?') {
                lex.type = GrLexeme.Type.optionalOr;
                lex._textLength = 2;
                _current++;
                if (_current + 1 >= _text.length)
                    break;
                if (get(1) == '=') {
                    lex.type = GrLexeme.Type.optionalOrAssign;
                    lex._textLength = 3;
                    _current++;
                }
            }
            break;
        default:
            raiseError(Error.invalidOp);
        }

        _lexemes ~= lex;

        /*
            Pour empêcher un problème lié à la mauvaise interprétation entre
            les opérateurs >> ou >= d’une opération arithmétique et
            deux > > successifs ou > = lié à l’expression d’un type ;
            on ajoute un lexème vide qui pourra être utilisé à la volonté du
            parseur, celui-ci doit être ignoré par le `advance()`.
        */
        if (lex.type == GrLexeme.Type.rightShift || lex.type == GrLexeme.Type.greaterOrEqual) {
            lex.type = GrLexeme.Type.nothing;
            lex._textLength = 1;
            _lexemes ~= lex;
        }
    }

    /**
	Scan a known keyword or an identifier otherwise.
	*/
    private void scanWord() {
        GrLexeme lex = GrLexeme(this);
        lex.isKeyword = true;

        dstring buffer;
        for (;;) {
            if (_current >= _text.length)
                break;

            const dchar symbol = get();
            /*if (symbol == '?') {
                buffer ~= symbol;
                _current++;
                break;
            }*/
            if (symbol <= '&' || (symbol >= '(' && symbol <= '/') || (symbol >= ':' &&
                    symbol <= '@') || (symbol >= '[' && symbol <= '^') ||
                (symbol >= '{' && symbol <= 0x7F))
                break;

            buffer ~= symbol;
            _current++;
        }
        _current--;

        lex._textLength = cast(uint) buffer.length;

        switch (buffer) {
        case "import":
            scanUse();
            return;
        case "public":
            lex.type = GrLexeme.Type.public_;
            break;
        case "const":
            lex.type = GrLexeme.Type.const_;
            break;
        case "pure":
            lex.type = GrLexeme.Type.pure_;
            break;
        case "alias":
            lex.type = GrLexeme.Type.alias_;
            break;
        case "class":
            lex.type = GrLexeme.Type.class_;
            break;
        case "enum":
            lex.type = GrLexeme.Type.enum_;
            break;
        case "where":
            lex.type = GrLexeme.Type.where;
            break;
        case "if":
            lex.type = GrLexeme.Type.if_;
            break;
        case "unless":
            lex.type = GrLexeme.Type.unless;
            break;
        case "else":
            lex.type = GrLexeme.Type.else_;
            break;
        case "switch":
            lex.type = GrLexeme.Type.switch_;
            break;
        case "select":
            lex.type = GrLexeme.Type.select;
            break;
        case "case":
            lex.type = GrLexeme.Type.case_;
            break;
        case "default":
            lex.type = GrLexeme.Type.default_;
            break;
        case "while":
            lex.type = GrLexeme.Type.while_;
            break;
        case "do":
            lex.type = GrLexeme.Type.do_;
            break;
        case "until":
            lex.type = GrLexeme.Type.until;
            break;
        case "for":
            lex.type = GrLexeme.Type.for_;
            break;
        case "loop":
            lex.type = GrLexeme.Type.loop;
            break;
        case "return":
            lex.type = GrLexeme.Type.return_;
            break;
        case "self":
            lex.type = GrLexeme.Type.self;
            break;
        case "die":
            lex.type = GrLexeme.Type.die;
            break;
        case "exit":
            lex.type = GrLexeme.Type.exit;
            break;
        case "yield":
            lex.type = GrLexeme.Type.yield;
            break;
        case "break":
            lex.type = GrLexeme.Type.break_;
            break;
        case "continue":
            lex.type = GrLexeme.Type.continue_;
            break;
        case "as":
            lex.type = GrLexeme.Type.as;
            break;
        case "try":
            lex.type = GrLexeme.Type.try_;
            break;
        case "catch":
            lex.type = GrLexeme.Type.catch_;
            break;
        case "throw":
            lex.type = GrLexeme.Type.throw_;
            break;
        case "defer":
            lex.type = GrLexeme.Type.defer;
            break;
        case "func":
            lex.type = GrLexeme.Type.func;
            lex.isType = true;
            break;
        case "task":
            lex.type = GrLexeme.Type.task;
            lex.isType = true;
            break;
        case "event":
            lex.type = GrLexeme.Type.event;
            lex.isType = true;
            break;
        case "int":
            lex.type = GrLexeme.Type.integerType;
            lex.isType = true;
            break;
        case "float":
            lex.type = GrLexeme.Type.floatType;
            lex.isType = true;
            break;
        case "bool":
            lex.type = GrLexeme.Type.booleanType;
            lex.isType = true;
            break;
        case "string":
            lex.type = GrLexeme.Type.stringType;
            lex.isType = true;
            break;
        case "list":
            lex.type = GrLexeme.Type.listType;
            lex.isType = true;
            break;
        case "channel":
            lex.type = GrLexeme.Type.channelType;
            lex.isType = true;
            break;
        case "var":
            lex.type = GrLexeme.Type.var;
            lex.isType = false;
            break;
        case "true":
            lex.type = GrLexeme.Type.bool_;
            lex.isKeyword = false;
            lex.isLiteral = true;
            lex.bvalue = true;
            break;
        case "false":
            lex.type = GrLexeme.Type.bool_;
            lex.isKeyword = false;
            lex.isLiteral = true;
            lex.bvalue = false;
            break;
        case "null":
            lex.type = GrLexeme.Type.null_;
            lex.isKeyword = false;
            lex.isLiteral = true;
            break;
        case "to":
            lex.type = GrLexeme.Type.interval;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "and":
            lex.type = GrLexeme.Type.and;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "or":
            lex.type = GrLexeme.Type.or;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "not":
            lex.type = GrLexeme.Type.not;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "bit_and":
            lex.type = GrLexeme.Type.bitwiseAnd;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "bit_or":
            lex.type = GrLexeme.Type.bitwiseOr;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "bit_xor":
            lex.type = GrLexeme.Type.bitwiseXor;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        case "bit_not":
            lex.type = GrLexeme.Type.bitwiseNot;
            lex.isKeyword = false;
            lex.isOperator = true;
            break;
        default:
            lex.isKeyword = false;
            lex.type = GrLexeme.Type.identifier;
            lex.svalue = to!string(buffer);
            break;
        }

        _lexemes ~= lex;
    }

    /// Transforme le chemin en chemin natif du système.
    private string convertPathToImport(string path) {
        import std.regex : replaceAll, regex;
        import std.path : dirSeparator;

        return replaceAll(path, regex(r"\\/|/|\\"), dirSeparator);
    }

    /// Ajoute un seul chemin de fichier délimité par `"` à la liste de fichiers à importer.
    private void scanFilePath() {
        import std.path : dirName, buildNormalizedPath, absolutePath;

        if (get() != '\"')
            raiseError(Error.expectedQuotationMarkAtBeginningOfStr);
        _current++;

        string buffer;
        for (;;) {
            if (_current >= _text.length)
                raiseError(Error.missingQuotationMarkAtEndOfStr);
            const dchar symbol = get();
            if (symbol == '\n') {
                _positionOfLine = _current;
                _line++;
            }
            else if (symbol == '\"')
                break;

            buffer ~= symbol;
            _current++;
        }
        string filePath = to!string(buffer);
        filePath = buildNormalizedPath(dirName(to!string(_file)), convertPathToImport(filePath));
        filePath = absolutePath(filePath);
        buffer = to!string(filePath);
        if (_filesImported.canFind(buffer) || _filesToImport.canFind(buffer))
            return;
        _filesToImport ~= buffer;
    }

    /// Analyse la directive `import`.
    /// Syntaxe:
    /// `import "CHEMIN/DU/FICHIER"` or
    /// `import { "CHEMIN1" "CHEMIN2" "CHEMIN3" }`
    /// ___
    /// Ajoute des fichier à la liste des fichiers à importer.
    private void scanUse() {
        advance();

        // Import de plusieurs fichiers
        if (get() == '{') {
            advance();
            bool isFirst = true;
            for (;;) {
                if (isFirst)
                    isFirst = false;
                else if (get() == '\"')
                    advance();
                else
                    raiseError(Error.missingQuotationMarkAtEndOfStr);

                // Fin du fichier
                if (_current >= _text.length)
                    raiseError(Error.missingRightCurlyBraceAfterUsedFilesList);

                // Fin de la liste
                if (get() == '}')
                    break;

                // Analyse le chemin
                scanFilePath();
            }
        }
        else {
            // Analyse le chemin
            scanFilePath();
        }
    }

    /// Erreur lexicale.
    private void raiseError(Error error) {
        raiseError(getLexerError(error, _locale));
    }
    /// Ditto
    private void raiseError(string message) {
        GrError error = new GrError;
        error.type = GrError.Type.lexer;

        error.message = message;
        error.info = "";

        if (_lexemes.length) {
            GrLexeme lexeme = _lexemes[$ - 1];
            error.filePath = to!string(lexeme.getFile());
            error.lineText = to!string(lexeme.getLine()).replace("\t", " ");
            error.line = lexeme._line + 1u; // Par convention, la première ligne comment à partir de 1, et non 0
            error.column = lexeme._column;
            error.textLength = lexeme._textLength;
        }
        else {
            error.filePath = to!string(_file);
            error.lineText = to!string(_lines[_line]);
            error.line = _line + 1u; // Par convention, la première ligne comment à partir de 1, et non 0
            error.column = _current - _positionOfLine;
            error.textLength = 0u;
        }

        throw new GrLexerException(error);
    }

    private enum Error {
        lexFileIdOutOfBounds,
        lexLineCountOutOfBounds,
        unexpectedEndOfFile,
        emptyNumber,
        expectedQuotationMarkAtBeginningOfStr,
        missingQuotationMarkAtEndOfStr,
        invalidOp,
        missingRightCurlyBraceAfterUsedFilesList
    }

    private string getLexerError(Error error, GrLocale locale) {
        immutable string[Error][GrLocale.max + 1] messages = [
            [
                Error.lexFileIdOutOfBounds: "lexeme file id out of bounds",
                Error.lexLineCountOutOfBounds: "lexeme line count out of bounds",
                Error.unexpectedEndOfFile: "unexpected end of file",
                Error.emptyNumber: "empty number",
                Error.expectedQuotationMarkAtBeginningOfStr: "expected `\"` at the beginning of the string",
                Error.missingQuotationMarkAtEndOfStr: "missing `\"` at the end of the string",
                Error.invalidOp: "invalid operator",
                Error.missingRightCurlyBraceAfterUsedFilesList: "missing `}` after used files list"
            ],
            [
                Error.lexFileIdOutOfBounds: "l’id de fichier du lexeme excède les limites",
                Error.lexLineCountOutOfBounds: "le numéro de ligne du lexeme excède les limites",
                Error.unexpectedEndOfFile: "fin de fichier inattendue",
                Error.emptyNumber: "nombre vide",
                Error.expectedQuotationMarkAtBeginningOfStr: "`\"` attendu au début de la chaîne",
                Error.missingQuotationMarkAtEndOfStr: "`\"` manquant en fin de chaîne",
                Error.invalidOp: "opérateur invalide",
                Error.missingRightCurlyBraceAfterUsedFilesList: "`}` manquant après la liste des fichiers utilisés"
            ]
        ];
        return messages[locale][error];
    }
}

private immutable string[] _prettyLexemeTypeTable = [
    "", "[", "]", "(", ")", "{", "}", ".", ";", ":", "::", ",", "@", "$",
    "?", "as", "try", "catch", "error", "defer", "=", "&=", "|=", "^=", "&&=",
    "||=", "??=", "+=", "-=", "*=", "/=", "~=", "%=", "**=", "+", "-", "&",
    "|", "^", "&&", "||", "??", "+", "-", "*", "/", "~", "%", "**", "==",
    "===", "<=>", "!=", ">=", ">", "<=", "<", "<<", ">>", "->", "=>", "~", "!",
    "++", "--", "identifier", "const_int", "const_float", "const_bool",
    "const_string", "null", "public", "const", "pure", "alias", "class", "enum",
    "where", "copy", "send", "receive", "int", "float", "bool", "string",
    "list", "channel", "func", "task", "event", "var", "if", "unless", "else",
    "switch", "select", "case", "default", "while", "do", "until", "for",
    "loop", "return", "self", "die", "exit", "yield", "break", "continue"
];

/// Renvoie une version affichable du type de jeton
string grGetPrettyLexemeType(GrLexeme.Type lexType) {
    return _prettyLexemeTypeTable[lexType];
}

/// Décrit une erreur lexicale
package final class GrLexerException : Exception {
    GrError error;

    this(GrError error_, string _file = __FILE__, size_t _line = __LINE__) {
        super(error_.message, _file, _line);
        error = error_;
    }
}
