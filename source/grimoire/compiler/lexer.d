/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.compiler.lexer;

import std.algorithm : canFind;
import std.array;
import std.exception : enforce;
import std.conv : to, ConvOverflowException;
import std.file;
import std.math;
import std.path : setExtension;
import std.stdio;
import std.string;

import grimoire.assembly;
import grimoire.compiler.data;
import grimoire.compiler.error;
import grimoire.compiler.library;
import grimoire.compiler.util;

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
        uint_,
        byte_,
        char_,
        float_,
        double_,
        bool_,
        string_,
        null_,
        export_,
        const_,
        pure_,
        alias_,
        class_,
        enum_,
        where,
        copy,
        send,
        receive,
        intType,
        uintType,
        byteType,
        charType,
        floatType,
        doubleType,
        boolType,
        stringType,
        listType,
        channelType,
        func,
        task,
        event,
        instance,
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
        function_,
        die,
        exit,
        yield,
        break_,
        continue_,
    }

    private this(GrLexer _lexer) {
        _file = _lexer._file;
        _line = _lexer._line;
        _column = _lexer._current >= _lexer._positionOfLine ?
            (_lexer._current - _lexer._positionOfLine) : 0;
        _fileId = _lexer._fileId;
        lexer = _lexer;
    }

    private {
        /// Le lexer parent
        GrLexer lexer;

        /// L’id du fichier dans lequel il est présent
        size_t _fileId;

        /// Le fichier dans lequel il est présent
        GrImportFile _file;

        /// Informations sur sa position en cas d’erreur
        size_t _line, _column, _textLength = 1;
    }

    @property {
        /// Sa ligne
        size_t line() const {
            return _line + _file.getLineOffset();
        }
        /// Ditto
        size_t rawLine() const {
            return _line;
        }
        /// Sa colonne
        size_t column() const {
            return _column;
        }
        /// Taille du texte
        size_t textLength() const {
            return _textLength;
        }
        /// Ditto
        size_t textLength(size_t textLength_) {
            return _textLength = textLength_;
        }
        /// L’id du fichier
        size_t fileId() const {
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

    union {
        /// Valeur entière de la constante.
        /// `isLiteral` vaut `true` et `type` vaut `int_`.
        GrInt intValue;

        /// Valeur entière non-signée de la constante.
        /// `isLiteral` vaut `true` et `type` vaut `uint_`.
        GrUInt uintValue;

        /// Valeur entière non-signée sur 1 octet de la constante.
        /// `isLiteral` vaut `true` et `type` vaut `byte_`.
        GrByte byteValue;

        /// Valeur flottante de la constante.
        /// `isLiteral` vaut `true` et `type` vaut `float_`.
        GrFloat floatValue;

        /// Valeur flottante en double-précision de la constante.
        /// `isLiteral` vaut `true` et `type` vaut `double_`.
        GrDouble doubleValue;

        /// Valeur booléenne de la constante.
        /// `isLiteral` vaut `true` et `type` vaut `bool_`.
        GrBool boolValue;
    }

    /// Décrit soit une valeur constante comme `"bonjour"` ou un identificateur.
    string strValue;

    /// Renvoie la ligne entière où le jeton est situé.
    string getLine() nothrow {
        dstring txt;
        try {
            txt = _file.getText();
            dstring[] lines = split(txt, "\n");
            if (_line >= lines.length)
                return "";
            return to!string(lines[_line]);
        }
        catch (Exception e) {
            return "";
        }
    }

    /// Renvoie le nom du fichier où le jeton est situé.
    string getFile() const nothrow {
        return _file.getPath();
    }
}

/// Fichier de compilation
package final class GrImportFile {
    enum Type {
        virtual,
        system,
        library
    }

    private {
        Type _type;

        string _path;
        size_t _line;
        dstring _source;
    }

    @property Type type() const {
        return _type;
    }

    static {
        /// Construit un fichier depuis du code source
        GrImportFile fromSource(dstring source, string path, size_t line) {
            GrImportFile file = new GrImportFile;
            file._make!(Type.virtual)(source, path, line);
            return file;
        }

        /// Construit un fichier depuis un fichier système
        GrImportFile fromPath(string path, GrImportFile relativeTo = null) {
            GrImportFile file = new GrImportFile;
            file._make!(Type.system)(_sanitizePath(path, relativeTo));
            return file;
        }

        /// Construit un fichier depuis un fichier système
        GrImportFile fromLibrary(string path, GrImportFile relativeTo = null) {
            GrImportFile file = new GrImportFile;
            file._make!(Type.library)(_sanitizePath(path, relativeTo));
            return file;
        }

        /// Transforme le chemin en chemin natif du système
        private string _sanitizePath(string path, GrImportFile relativeTo = null) {
            import std.path : dirName, buildNormalizedPath, absolutePath;
            import std.regex : replaceAll, regex;
            import std.path : dirSeparator;

            path = replaceAll(path, regex(r"\\/|/|\\"), dirSeparator);

            if (relativeTo)
                path = buildNormalizedPath(dirName(relativeTo._path), path);
            else
                path = buildNormalizedPath(path);

            return absolutePath(path);
        }
    }

    private this() {
    }

    /// Construit un fichier depuis du code source
    private void _make(Type type = Type.virtual)(dstring source, string path, size_t line) {
        _type = type;
        _source = source;
        _path = path;
        _line = line;
    }

    /// Construit un fichier depuis un fichier système
    private void _make(Type type = Type.system)(string path) {
        _type = type;
        _path = path;
    }

    /// Retourne le contenu du fichier
    dstring getText() const {
        final switch (_type) with (Type) {
        case virtual:
            return _source;
        case system:
            return to!dstring(readText(_path));
        case library:
            assert(false, "can’t fetch text of a library");
        }
    }

    /// Retourne le chemin du fichier
    string getPath() const nothrow {
        return _path;
    }

    /// La ligne de départ du fichier
    size_t getLineOffset() const {
        final switch (_type) with (Type) {
        case virtual:
            return _line;
        case system:
            return 1; // Par convention, la première ligne commence à 1, et non 0.
        case library:
            assert(false, "can’t fetch line of a library");
        }
    }

    bool opEquals(const GrImportFile other) const {
        final switch (_type) with (Type) {
        case virtual:
            return false;
        case system:
        case library:
            return (_type == other._type) && (_path == other._path);
        }
    }

    override size_t toHash() const @trusted {
        return typeid(this).getHash(cast(void*) this);
    }
}

/// Le lexeur analyse l’entièreté du fichier et importe tous les fichiers qui y sont référencés,
/// puis génère une série de lexème qui seront analysé par le parseur.
package final class GrLexer {
    private {
        GrImportFile[] _filesToImport, _filesImported, _libraries;
        GrImportFile _file;
        dstring[] _lines;
        dstring _text;
        size_t _line, _current, _positionOfLine, _fileId;
        GrLexeme[] _lexemes;
        GrLocale _locale;
        GrData _data;
        GrLibrary[] _librariesImported;
    }

    @property {
        /// Tous les jetons générés.
        GrLexeme[] lexemes() {
            return _lexemes;
        }

        /// Les bibliothèques chargés
        GrImportFile[] libraries() {
            return _libraries;
        }
    }

    this(GrLocale locale) {
        _locale = locale;
    }

    void addFile(GrImportFile file) {
        final switch (file.type) with (GrImportFile.Type) {
        case library: {
                foreach (other; _libraries) {
                    if (file == other)
                        return;
                }

                _libraries ~= file;
                break;
            }
        case virtual:
        case system: {
                foreach (other; _filesToImport) {
                    if (file == other)
                        return;
                }

                foreach (other; _filesImported) {
                    if (file == other)
                        return;
                }
            }
            _filesToImport ~= file;
            break;
        }

    }

    /// Analyse le fichier racine et toutes ses dépendances.
    void scan(GrData data) {
        _data = data;

        while (_filesToImport.length) {
            _file = _filesToImport[$ - 1];
            _filesImported ~= _file;
            _text = _file.getText();
            _filesToImport.length--;

            _line = 0u;
            _current = 0u;
            _positionOfLine = 0u;
            _lines = split(_text, "\n");

            if (data.definitionTable) {
                data.definitionTable.addFile(_fileId, _file.getPath());
            }

            scanScript();

            _fileId++;
        }

        importLibraries();

        if (data.definitionTable) {
            data.definitionTable.setLexemes(_lexemes);
        }
    }

    private void importLibraries() {
        import core.runtime;

        foreach (file; _libraries) {
            assert(file.type == GrImportFile.Type.library, "invalid library file type");
            string filePath = file.getPath();

            void* dlib;

            version (Windows) {
                dlib = Runtime.loadLibrary(filePath);
            }
            else version (Posix) {
                import core.sys.posix.dlfcn : dlopen, RTLD_LAZY;

                dlib = dlopen(toStringz(filePath), RTLD_LAZY);
            }
            enforce!GrCompilerException(dlib, format(getError(Error.libXNotFound), filePath));

            typeof(&_GRLIBSYMBOL) libFunc;

            version (Windows) {
                import core.sys.windows.winbase : GetProcAddress;

                libFunc = cast(typeof(&_GRLIBSYMBOL)) GetProcAddress(dlib,
                    toStringz(_GRLIBSYMBOLMANGLED));
            }
            else version (Posix) {
                import core.sys.posix.dlfcn : dlsym;

                libFunc = cast(typeof(&_GRLIBSYMBOL)) dlsym(dlib, toStringz(_GRLIBSYMBOLMANGLED));
            }
            enforce!GrCompilerException(libFunc, format(getError(Error.libXNotValid), filePath));

            _librariesImported ~= libFunc();
        }
    }

    package GrLibrary[] getLibraries() {
        return _librariesImported;
    }

    /// Ditto
    package string getFile(size_t fileId) nothrow {
        if (fileId >= _filesImported.length)
            return "";
        return _filesImported[fileId].getPath();
    }

    /// Renvoie le caractère présent à la position du curseur.
    private dchar get(int offset = 0) {
        const uint position = to!int(_current) + offset;
        if (position < 0 || position >= _text.length)
            logError(Error.unexpectedEndOfFile);
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
                _positionOfLine = _current + 1;
                _line++;
            }
            else if (symbol == '#') {
                do {
                    if (_current >= _text.length)
                        return false;
                    _current++;
                }
                while (_text[_current] != '\n');
                _positionOfLine = _current + 1;
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
                    _positionOfLine = _current + 1;
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
                            _positionOfLine = _current + 1;
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
    private void scanScript(bool matchBlock = false) {
        // On ignore les espaces/commentaires situés au début
        advance(true);

        if (_current >= _text.length) {
            _lexemes ~= GrLexeme(this);
        }

        uint blockLevel;

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
            case '|':
            case '~':
                scanOperator();
                break;
            case '{':
                if (matchBlock) {
                    blockLevel++;
                }
                goto case '@';
            case '}':
                if (matchBlock) {
                    if (!blockLevel) {
                        return;
                    }
                    blockLevel--;
                }
                goto case '@';
            case '\'':
                scanChar();
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
	Analyse un nombre littéral. \
	Les tirets du bas `_` sont ignorés à l’intérieur d’un nombre.
    - Un entier hexadécimal commence par 0x ou 0X.
    - Un entier octal commence par 0o ou 0o.
    - Un entier binaire commence par 0b ou 0b.
    - Un nombre flottant peut commencer par un point ou avoir un point au milieu mais pas finir par un point.
    - Un nombre flottant peut finir par un `f`.
	*/
    private void scanNumber() {
        GrLexeme lex = GrLexeme(this);
        lex.isLiteral = true;

        bool isStart = true;
        bool isPrefix, isMaybeFloat, isFloat, isDouble, isUnsigned, isByte;
        bool isBinary, isOctal, isHexadecimal;
        string buffer;

        lex._textLength = 0;

        for (;;) {
            dchar symbol = get();

            if (isBinary) {
                if (symbol == '0' || symbol == '1') {
                    buffer ~= symbol;
                    lex._textLength++;
                }
                else if (symbol == '_') {
                    // On ne fait rien, c’est purement visuel (par ex: 0b1111_1111)
                    lex._textLength++;
                }
                else {
                    if (_current)
                        _current--;
                    break;
                }
            }
            else if (isOctal) {
                if (symbol >= '0' && symbol <= '7') {
                    buffer ~= symbol;
                    lex._textLength++;
                }
                else if (symbol == '_') {
                    // On ne fait rien, c’est purement visuel (par ex: 0o7_77)
                    lex._textLength++;
                }
                else {
                    if (_current)
                        _current--;
                    break;
                }
            }
            else if (isHexadecimal) {
                if ((symbol >= '0' && symbol <= '9') || (symbol >= 'a' &&
                        symbol <= 'f') || (symbol >= 'A' && symbol <= 'F')) {
                    buffer ~= symbol;
                    lex._textLength++;
                }
                else if (symbol == '_') {
                    // On ne fait rien, c’est purement visuel (par ex: 0xff_ff)
                    lex._textLength++;
                }
                else {
                    if (_current)
                        _current--;
                    break;
                }
            }
            else if (isPrefix && (symbol == 'b' || symbol == 'B')) {
                isPrefix = false;
                isBinary = true;
                buffer.length = 0;
                lex._textLength++;
            }
            else if (isPrefix && (symbol == 'o' || symbol == 'O')) {
                isPrefix = false;
                isOctal = true;
                buffer.length = 0;
                lex._textLength++;
            }
            else if (isPrefix && (symbol == 'x' || symbol == 'X')) {
                isPrefix = false;
                isHexadecimal = true;
                buffer.length = 0;
                lex._textLength++;
            }
            else if (symbol >= '0' && symbol <= '9') {
                if (isStart && symbol == '0') {
                    isPrefix = true;
                }
                else if (isMaybeFloat) {
                    buffer ~= '.';
                    isMaybeFloat = false;
                    isFloat = true;
                    isDouble = true;
                }

                buffer ~= symbol;
                lex._textLength++;
            }
            else if (symbol == '_') {
                // On ne fait rien, c’est purement visuel (par ex: 1_000_000)
                lex._textLength++;
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
                isDouble = true;
                lex._textLength++;
            }
            else if (symbol == 'f' || symbol == 'F') {
                if (isMaybeFloat) {
                    _current--;
                    break;
                }
                isFloat = true;
                isDouble = false;
                lex._textLength++;
                break;
            }
            else if (symbol == 'd' || symbol == 'D') {
                if (isMaybeFloat) {
                    _current--;
                    break;
                }
                isFloat = true;
                isDouble = true;
                lex._textLength++;
                break;
            }
            else if (symbol == 'u' || symbol == 'U') {
                if (isMaybeFloat || isFloat) {
                    _current--;
                    break;
                }
                isUnsigned = true;
                lex._textLength++;
                break;
            }
            else if (symbol == 'b' || symbol == 'B') {
                if (isMaybeFloat || isFloat) {
                    _current--;
                    break;
                }
                isByte = true;
                lex._textLength++;
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

        if (!buffer.length && !isFloat) {
            lex.type = GrLexeme.Type.int_;
            lex.intValue = 0;
            _lexemes ~= lex;
            logError(Error.emptyNumber);
        }

        try {
            if (isBinary) {
                lex.type = GrLexeme.Type.int_;
                lex.intValue = to!GrInt(buffer, 2);
            }
            else if (isOctal) {
                lex.type = GrLexeme.Type.int_;
                lex.intValue = to!GrInt(buffer, 8);
            }
            else if (isHexadecimal) {
                lex.type = GrLexeme.Type.int_;
                lex.intValue = to!GrInt(buffer, 16);
            }
            else if (isFloat) {
                if (isDouble) {
                    lex.type = GrLexeme.Type.double_;
                    lex.doubleValue = to!GrDouble(buffer);
                }
                else {
                    lex.type = GrLexeme.Type.float_;
                    lex.floatValue = to!GrFloat(buffer);
                }
            }
            else if (isUnsigned) {
                lex.type = GrLexeme.Type.uint_;
                lex.uintValue = to!GrUInt(buffer);
            }
            else if (isByte) {
                lex.type = GrLexeme.Type.byte_;
                lex.byteValue = to!GrByte(buffer);
            }
            else {
                const long value = to!long(buffer);

                if (value > int.max && value <= uint.max) {
                    lex.type = GrLexeme.Type.uint_;
                    lex.uintValue = cast(GrUInt) value;
                }
                else if (value >= int.min && value <= int.max) {
                    lex.type = GrLexeme.Type.int_;
                    lex.intValue = cast(GrInt) value;
                }
                else {
                    lex.type = GrLexeme.Type.int_;
                    lex.intValue = 0;
                    _lexemes ~= lex;
                    logError(Error.numberTooBig);
                }
            }
        }
        catch (ConvOverflowException) {
            lex.type = GrLexeme.Type.int_;
            lex.intValue = 0;
            _lexemes ~= lex;
            logError(Error.numberTooBig);
        }
        _lexemes ~= lex;
    }

    /// Analyse une séquence d’échappement
    private dchar scanEscapeCharacter(ref uint textLength) {
        dchar symbol;
        textLength = 1;

        // Pour la gestion d’erreur
        GrLexeme lex = GrLexeme(this);
        lex.isLiteral = true;

        if (get() != '\\') {
            symbol = get();
            _current++;
            return symbol;
        }
        _current++;
        textLength = 2;

        switch (get()) {
        case '\'':
            symbol = '\'';
            break;
        case '\\':
            symbol = '\\';
            break;
        case '?':
            symbol = '\?';
            break;
        case '0':
            symbol = '\0';
            break;
        case 'a':
            symbol = '\a';
            break;
        case 'b':
            symbol = '\b';
            break;
        case 'f':
            symbol = '\f';
            break;
        case 'n':
            symbol = '\n';
            break;
        case 'r':
            symbol = '\r';
            break;
        case 't':
            symbol = '\t';
            break;
        case 'v':
            symbol = '\v';
            break;
        case 'u':
            _current++;
            textLength++;

            if (get() != '{') {
                lex = GrLexeme(this);
                _lexemes ~= lex;
                logError(Error.expectedLeftCurlyBraceInUnicode);
            }
            _current++;
            textLength++;

            dstring buffer;
            while ((symbol = get()) != '}') {
                if ((symbol >= '0' && symbol <= '9') || (symbol >= 'a' &&
                        symbol <= 'f') || (symbol >= 'A' && symbol <= 'F')) {
                    buffer ~= symbol;
                    textLength++;
                }
                else {
                    lex = GrLexeme(this);
                    _lexemes ~= lex;
                    logError(Error.unexpectedSymbolInUnicode);
                }
                _current++;
            }
            textLength++;

            try {
                const ulong value = to!ulong(buffer, 16);

                if (value > 0x10FFFF) {
                    lex.textLength = textLength;
                    _lexemes ~= lex;
                    logError(Error.unicodeTooBig);
                }
                symbol = cast(dchar) value;
            }
            catch (ConvOverflowException e) {
                lex.textLength = textLength;
                _lexemes ~= lex;
                logError(Error.unicodeTooBig);
            }

            break;
        default:
            symbol = get();
            break;
        }
        _current++;

        return symbol;
    }

    /// Analyse un caractère délimité par des `'`.
    void scanChar() {
        GrLexeme lex = GrLexeme(this);
        lex.type = GrLexeme.Type.char_;
        lex.isLiteral = true;
        uint textLength = 0;

        if (get() != '\'') {
            lex = GrLexeme(this);
            lex.isLiteral = true;
            _lexemes ~= lex;
            logError(Error.expectedQuoteStartChar);
        }
        _current++;
        textLength++;

        dchar ch = get();

        if (ch == '\\') {
            ch = scanEscapeCharacter(textLength);
        }
        else {
            _current++;
            textLength++;
        }

        textLength++;
        lex.textLength = textLength;
        lex.uintValue = cast(GrUInt) ch;
        _lexemes ~= lex;

        if (get() != '\'') {
            lex = GrLexeme(this);
            lex.isLiteral = true;
            _lexemes ~= lex;
            logError(Error.missingQuoteEndChar);
        }
    }

    /// Analyse une chaîne de caractères délimité par des `"`.
    void scanString() {
        GrLexeme lex = GrLexeme(this);
        lex.type = GrLexeme.Type.string_;
        lex.isLiteral = true;
        uint textLength = 0;

        if (get() != '\"')
            logError(Error.expectedQuoteStartString);
        _current++;
        textLength++;

        string buffer;
        for (;;) {
            if (_current >= _text.length)
                logError(Error.missingQuoteEndString);
            const dchar symbol = get();

            if (symbol == '\n') {
                _positionOfLine = _current + 1;
                _line++;

                buffer ~= get();
                _current++;
                textLength++;
            }
            else if (symbol == '\"')
                break;
            else if (symbol == '\\')
                buffer ~= scanEscapeCharacter(textLength);
            else if (symbol == '#') {
                _current++;
                textLength++;

                if (get() == '{') {
                    _current++;
                    textLength++;

                    lex.textLength = textLength;
                    lex.strValue = buffer;
                    _lexemes ~= lex;

                    // Concaténation
                    GrLexeme concatLex = GrLexeme(this);
                    concatLex.isOperator = true;
                    concatLex.type = GrLexeme.Type.concatenate;
                    _lexemes ~= concatLex;

                    scanScript(true);

                    if (get() != '}') {
                        lex = GrLexeme(this);
                        _lexemes ~= lex;
                        logError(Error.invalidOp);
                    }

                    // Concaténation
                    _lexemes ~= concatLex;

                    _current++;
                    textLength = 1;
                    buffer.length = 0;
                }
                else {
                    buffer ~= '#';
                }
            }
            else {
                buffer ~= get();
                _current++;
                textLength++;
            }
        }
        textLength++;

        lex.textLength = textLength;
        lex.strValue = buffer;
        _lexemes ~= lex;
    }

    /// Analyse un opérateur basé sur des symboles.
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
            logError(Error.invalidOp);
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

    /// Analyse un mot-clé connu ou un identificateur dans le cas échéant.
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
            scanImport();
            return;
        case "export":
            lex.type = GrLexeme.Type.export_;
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
        case "function":
            lex.type = GrLexeme.Type.function_;
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
        case "instance":
            lex.type = GrLexeme.Type.instance;
            lex.isType = true;
            break;
        case "int":
            lex.type = GrLexeme.Type.intType;
            lex.isType = true;
            break;
        case "uint":
            lex.type = GrLexeme.Type.uintType;
            lex.isType = true;
            break;
        case "byte":
            lex.type = GrLexeme.Type.byteType;
            lex.isType = true;
            break;
        case "char":
            lex.type = GrLexeme.Type.charType;
            lex.isType = true;
            break;
        case "float":
            lex.type = GrLexeme.Type.floatType;
            lex.isType = true;
            break;
        case "double":
            lex.type = GrLexeme.Type.doubleType;
            lex.isType = true;
            break;
        case "bool":
            lex.type = GrLexeme.Type.boolType;
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
            lex.boolValue = true;
            break;
        case "false":
            lex.type = GrLexeme.Type.bool_;
            lex.isKeyword = false;
            lex.isLiteral = true;
            lex.boolValue = false;
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
            lex.strValue = to!string(buffer);
            break;
        }

        _lexemes ~= lex;
    }

    /// Ajoute un seul chemin de fichier délimité par `"` à la liste de fichiers à importer.
    private void scanFilePath() {
        dchar endChar;
        bool isLibrary;

        switch (get()) {
        case '\"':
            endChar = '\"';
            break;
        case '<':
            endChar = '>';
            isLibrary = true;
            break;
        default:
            logError(Error.expectedQuoteStartString);
        }
        _current++;

        string buffer;
        for (;;) {
            if (_current >= _text.length)
                logError(Error.missingQuoteEndString);
            const dchar symbol = get();
            if (symbol == '\n') {
                _positionOfLine = _current + 1;
                _line++;
            }
            else if (symbol == endChar)
                break;

            buffer ~= symbol;
            _current++;
        }

        if (isLibrary) {
            addFile(GrImportFile.fromLibrary(buffer, _file));
        }
        else {
            addFile(GrImportFile.fromPath(buffer, _file));
        }
    }

    /// Analyse la directive `import`.
    /// Syntaxe:
    /// `import "CHEMIN/DU/FICHIER"` or
    /// `import { "CHEMIN1" "CHEMIN2" "CHEMIN3" }`
    /// ___
    /// Ajoute des fichier à la liste des fichiers à importer.
    private void scanImport() {
        advance();

        // Import de plusieurs fichiers
        if (get() == '{') {
            advance();
            bool isFirst = true;
            for (;;) {
                if (isFirst)
                    isFirst = false;
                else if (get() == '\"' || get() == '>')
                    advance();
                else
                    logError(Error.missingQuoteEndString);

                // Fin du fichier
                if (_current >= _text.length)
                    logError(Error.missingRightCurlyBraceAfterUsedFilesList);

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
    private void logError(Error error) {
        logError(getError(error));
    }
    /// Ditto
    private void logError(string message) {
        GrError error = new GrError;
        error.type = GrError.Type.lexer;

        error.message = message;
        error.info = "";

        if (_lexemes.length) {
            GrLexeme lexeme = _lexemes[$ - 1];
            error.filePath = to!string(lexeme.getFile());
            error.lineText = to!string(lexeme.getLine()).replace("\t", " ");
            error.line = lexeme._line + 1u; // Par convention, la première ligne commence à partir de 1, et non 0
            error.column = lexeme._column;
            error.textLength = lexeme._textLength;
        }
        else {
            error.filePath = to!string(_file);
            error.lineText = to!string(_lines[_line]);
            error.line = _line + 1u; // Par convention, la première ligne commence à partir de 1, et non 0
            error.column = _current >= _positionOfLine ? (_current - _positionOfLine) : 0;
            error.textLength = 0u;
        }

        throw new GrLexerException(error);
    }

    private enum Error {
        lexFileIdOutOfBounds,
        lexLineCountOutOfBounds,
        unexpectedEndOfFile,
        emptyNumber,
        numberTooBig,
        expectedLeftCurlyBraceInUnicode,
        unexpectedSymbolInUnicode,
        unicodeTooBig,
        expectedQuoteStartChar,
        missingQuoteEndChar,
        expectedQuoteStartString,
        missingQuoteEndString,
        invalidOp,
        missingRightCurlyBraceAfterUsedFilesList,
        libXNotFound,
        libXNotValid
    }

    private string getError(Error error) {
        final switch (_locale) with (GrLocale) {
        case en_US:
            final switch (error) with (Error) {
            case lexFileIdOutOfBounds:
                return "lexeme file id out of bounds";
            case lexLineCountOutOfBounds:
                return "lexeme line count out of bounds";
            case unexpectedEndOfFile:
                return "unexpected end of file";
            case emptyNumber:
                return "empty number";
            case numberTooBig:
                return "number too big";
            case expectedLeftCurlyBraceInUnicode:
                return "expected `{` in an unicode escape sequence";
            case unexpectedSymbolInUnicode:
                return "unexpected symbol in an unicode escape sequence";
            case unicodeTooBig:
                return "unicode must be at most 10FFFF";
            case expectedQuoteStartChar:
                return "expected `'` at the start of the string";
            case missingQuoteEndChar:
                return "missing `'` at the end of the string";
            case expectedQuoteStartString:
                return "expected `\"` at the start of the string";
            case missingQuoteEndString:
                return "missing `\"` at the end of the string";
            case invalidOp:
                return "invalid operator";
            case missingRightCurlyBraceAfterUsedFilesList:
                return "missing `}` after used files list";
            case libXNotFound:
                return "the library `%s` can’t be found";
            case libXNotValid:
                return "the library `%s` is not a valid library";
            }
        case fr_FR:
            final switch (error) with (Error) {
            case lexFileIdOutOfBounds:
                return "l’id de fichier du lexeme excède les limites";
            case lexLineCountOutOfBounds:
                return "le numéro de ligne du lexeme excède les limites";
            case unexpectedEndOfFile:
                return "fin de fichier inattendue";
            case emptyNumber:
                return "nombre vide";
            case numberTooBig:
                return "nombre trop grand";
            case expectedLeftCurlyBraceInUnicode:
                return "`{` attendu dans la séquence d’échappement d’un unicode";
            case unexpectedSymbolInUnicode:
                return "symbole inattendu dans une séquence d’échappement d’un unicode";
            case unicodeTooBig:
                return "un unicode ne doit pas valoir plus de 10FFFF";
            case expectedQuoteStartChar:
                return "`'` attendu en début de caractère";
            case missingQuoteEndChar:
                return "`'` manquant en fin de caractère";
            case expectedQuoteStartString:
                return "`\"` attendu en début de chaîne";
            case missingQuoteEndString:
                return "`\"` manquant en fin de chaîne";
            case invalidOp:
                return "opérateur invalide";
            case missingRightCurlyBraceAfterUsedFilesList:
                return "`}` manquant après la liste des fichiers utilisés";
            case libXNotFound:
                return "la bibliothèque `%s` est introuvable";
            case libXNotValid:
                return "la bibliothèque `%s` n’est pas une bibliothèque valide";
            }
        }
    }
}

/// Renvoie une version affichable du type de jeton
string grGetPrettyLexemeType(GrLexeme.Type lexType) {
    final switch (lexType) with (GrLexeme.Type) {
    case nothing:
        return "";
    case leftBracket:
        return "[";
    case rightBracket:
        return "]";
    case leftParenthesis:
        return "(";
    case rightParenthesis:
        return ")";
    case leftCurlyBrace:
        return "{";
    case rightCurlyBrace:
        return "}";
    case period:
        return ".";
    case semicolon:
        return ";";
    case colon:
        return ":";
    case doubleColon:
        return "::";
    case comma:
        return ",";
    case at:
        return "@";
    case pointer:
        return "$";
    case optional:
        return "?";
    case as:
        return "as";
    case try_:
        return "try";
    case catch_:
        return "catch";
    case throw_:
        return "error";
    case defer:
        return "defer";
    case assign:
        return "=";
    case bitwiseAndAssign:
        return "&=";
    case bitwiseOrAssign:
        return "|=";
    case bitwiseXorAssign:
        return "^=";
    case andAssign:
        return "&&=";
    case orAssign:
        return "||=";
    case optionalOrAssign:
        return "??=";
    case addAssign:
        return "+=";
    case substractAssign:
        return "-=";
    case multiplyAssign:
        return "*=";
    case divideAssign:
        return "/=";
    case concatenateAssign:
        return "~=";
    case remainderAssign:
        return "%=";
    case powerAssign:
        return "**=";
    case plus:
        return "+";
    case minus:
        return "-";
    case bitwiseAnd:
        return "&";
    case bitwiseOr:
        return "|";
    case bitwiseXor:
        return "^";
    case and:
        return "&&";
    case or:
        return "||";
    case optionalOr:
        return "??";
    case add:
        return "+";
    case substract:
        return "-";
    case multiply:
        return "*";
    case divide:
        return "/";
    case concatenate:
        return "~";
    case remainder:
        return "%";
    case power:
        return "**";
    case equal:
        return "==";
    case doubleEqual:
        return "===";
    case threeWayComparison:
        return "<=>";
    case notEqual:
        return "!=";
    case greaterOrEqual:
        return ">=";
    case greater:
        return ">";
    case lesserOrEqual:
        return "<=";
    case lesser:
        return "<";
    case leftShift:
        return "<<";
    case rightShift:
        return ">>";
    case interval:
        return "->";
    case arrow:
        return "=>";
    case bitwiseNot:
        return "~";
    case not:
        return "!";
    case increment:
        return "++";
    case decrement:
        return "--";
    case identifier:
        return "identifier";
    case int_:
        return "const_int";
    case uint_:
        return "const_uint";
    case byte_:
        return "const_byte";
    case char_:
        return "const_char";
    case float_:
        return "const_float";
    case double_:
        return "const_double";
    case bool_:
        return "const_bool";
    case string_:
        return "const_string";
    case null_:
        return "null";
    case export_:
        return "export";
    case const_:
        return "const";
    case pure_:
        return "pure";
    case alias_:
        return "alias";
    case class_:
        return "class";
    case enum_:
        return "enum";
    case where:
        return "where";
    case copy:
        return "copy";
    case send:
        return "send";
    case receive:
        return "receive";
    case intType:
        return "int";
    case uintType:
        return "uint";
    case byteType:
        return "byte";
    case charType:
        return "char";
    case floatType:
        return "float";
    case doubleType:
        return "double";
    case boolType:
        return "bool";
    case stringType:
        return "string";
    case listType:
        return "list";
    case channelType:
        return "channel";
    case func:
        return "func";
    case task:
        return "task";
    case event:
        return "event";
    case instance:
        return "instance";
    case var:
        return "var";
    case if_:
        return "if";
    case unless:
        return "unless";
    case else_:
        return "else";
    case switch_:
        return "switch";
    case select:
        return "select";
    case case_:
        return "case";
    case default_:
        return "default";
    case while_:
        return "while";
    case do_:
        return "do";
    case until:
        return "until";
    case for_:
        return "for";
    case loop:
        return "loop";
    case return_:
        return "return";
    case self:
        return "self";
    case function_:
        return "function";
    case die:
        return "die";
    case exit:
        return "exit";
    case yield:
        return "yield";
    case break_:
        return "break";
    case continue_:
        return "continue";
    }
}

/// Décrit une erreur lexicale
package final class GrLexerException : GrCompilerException {
    GrError error;

    this(GrError error_, string _file = __FILE__, size_t _line = __LINE__) {
        super(error_.message, _file, _line);
        error = error_;
    }
}
