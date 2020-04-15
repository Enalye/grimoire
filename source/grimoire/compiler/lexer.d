/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.lexer;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.math;
import std.file;
import std.algorithm: canFind;
import grimoire.compiler.error;

/**
Kinds of valid token.
*/
enum GrLexemeType {
	leftBracket, rightBracket, leftParenthesis, rightParenthesis, leftCurlyBrace, rightCurlyBrace,
	period, semicolon, methodCall, comma, at, pointer, as, is_, try_, catch_, raise_, defer,
	assign,
	addAssign, substractAssign, multiplyAssign, divideAssign, concatenateAssign, remainderAssign, powerAssign,
	plus, minus,
	add, substract, multiply, divide, concatenate, remainder, power,
	equal, notEqual, greaterOrEqual, greater, lesserOrEqual, lesser,
	and, or, xor, not,
	increment, decrement,
	identifier, integer, float_, boolean, string_,
	main_, event_, class_, enum_, new_, copy, send, receive,
	voidType, intType, floatType, boolType, stringType, arrayType, functionType, taskType, chanType, autoType,
	if_, unless, else_, switch_, select, case_, while_, do_, until, for_, loop, return_, self,
	kill, killAll, yield, break_, continue_,
}

/**
Describe the smallest element found in a source file.
*/
struct GrLexeme {
    /// Default.
	this(GrLexer _lexer) {
		line = _lexer.line;
		column = _lexer.current - _lexer.positionOfLine;
		fileId = _lexer.fileId;
		lexer = _lexer;
	}

    /// Parent lexer.
	private GrLexer lexer;

	/// Id of the file the token is in.
	private uint fileId;

    /// Position information in case of errors.
	uint line, column, textLength = 1;

	/// Kind of token.
	GrLexemeType type;

    /// Whether the lexeme is a constant value.
	bool isLiteral;

    /// Whether the lexeme is an operator.
	bool isOperator;

    /// is this a reserved grimoire word ?
	bool isKeyword;

    /// Only describe first class type such as `int`, `string` or `func`.
    /// Structure or other custom type are not.
	bool isType;

    /// Integral value of the constant.
    /// isLiteral will be true and type set to integer.
	int ivalue;

    /// Floating point value of the constant.
    /// isLiteral will be true and type set to float_.
	float fvalue;

    /// boolean value of the constant.
    /// isLiteral will be true and type set to boolean.
	bool bvalue;

    /// Can either describe a literal value like `"myString"` or an identifier.
	dstring svalue;

    /// Returns the entire line from where the token is located.
	dstring getLine() {
		return lexer.getLine(this);
	}

	dstring getFile() {
		return lexer.getFile(this);
	}
}

/**
The lexer scans the entire file and all the imported files it references.
*/
class GrLexer {
	dstring[] filesToImport, filesImported;
	dstring[] lines;
	dstring file, text;
	uint line, current, positionOfLine, fileId;
	GrLexeme[] lexemes;

	dchar get(int offset = 0) {
		const uint position = to!int(current) + offset;
		if(position < 0 || position >= text.length)
			raiseError("Unexpected end of script");
		return text[position];
	}

	package dstring getLine(GrLexeme lex) {
		if(lex.fileId >= filesImported.length)
			raiseError("Lexeme fileId out of bounds");
		auto text = to!dstring(readText(to!string(filesImported[lex.fileId])));
		lines = split(text, "\n");
		if(lex.line >= lines.length)
			raiseError("Lexeme line count out of bounds");
		return lines[lex.line];
	}

	package dstring getFile(GrLexeme lex) {
		if(lex.fileId >= filesImported.length)
			raiseError("Lexeme fileId out of bounds");
		return filesImported[lex.fileId];
	}

	/// Advance the current character pointer and skips whitespaces and comments.
	bool advance(bool startFromCurrent = false) {
        if(!startFromCurrent)
			current ++;

		if(current >= text.length)
			return false;

		dchar symbol = text[current];

		whileLoop: while(symbol <= 0x20 || symbol == '/' || symbol == '#') {
			if(current >= text.length)
				return false;

			symbol = text[current];

			if(symbol == '\n') {
				positionOfLine = current;
				line ++;
			}
            else if(symbol == '#') {
                do {
                    if((current + 1) >= text.length)
                        return false;
                    current ++;
                }
                while(text[current] != '\n');
                positionOfLine = current;
                line ++;
            }
			else if(symbol == '/') {
				if((current + 1) >= text.length)
					return false;

				switch(text[current + 1]) {
					case '/':
						do {
							if((current + 1) >= text.length)
								return false;
							current ++;
						}
						while(text[current] != '\n');
						positionOfLine = current;
						line ++;
						break;
					case '*':
						for(;;) {
							if((current + 2) >= text.length)
								return false;

							if(text[current] == '\n') {
								positionOfLine = current;
								line ++;
							}

							if(text[current] == '*' && text[current + 1] == '/') {
								current ++;
								break;
							}

							current ++;
						}
						
						break;
					default:
						break whileLoop;
				}
			}
			current ++;

			if(current >= text.length)
				return false;

			symbol = text[current];
		}
		return true;
	}

	/// Start scanning the root file and all its dependencies.
	void scanFile(dstring fileName) {
		import std.path: buildNormalizedPath, absolutePath;
		string filePath = to!string(fileName);
		filePath = buildNormalizedPath(convertPathToImport(filePath));
		filePath = absolutePath(filePath);
		fileName = to!dstring(filePath);

		filesToImport ~= fileName;

		while(filesToImport.length) {
			file = filesToImport[$-1];
			filesImported ~= file;
			text = to!dstring(readText(to!string(file)));
			filesToImport.length --;

			line = 0u;
			current = 0u;
			lines = split(text, "\n");

			scanScript();

			fileId ++;
		}
	}

	/// Scan the content of a single file.
	void scanScript() {
		//Skip the first escape characters.
		advance(true);
    
		do {
			if(current >= text.length)
				break;
			switch(get()) {
				case '0': .. case '9':
					scanNumber();
					break;
                case '.':
                    if(get(1) >= '0' && get(1) <= '9')
                        scanNumber();
                    else
                        goto case '!';
                    break;
				case '!':
				case '#': .. case '&':
				case '(': .. case '-':
				case '/':
				case ':': .. case '@':
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
        while(advance());
	}

	/**
	Outputs every tokens (lexemes) scanned.
	*/
	void debugShowScan() {
		writeln("Scan:");

		foreach(lexeme; lexemes) {
			writeln(lexeme);
		}
	}

	/**
	Scan either a integer or a floating point number. \
	Floats can start with a `.` \
	A number finishing with `f` will be scanned as a float. \
	Underscores `_` are ignored inside a number.
	*/
	void scanNumber() {
		GrLexeme lex = GrLexeme(this);
		lex.isLiteral = true;

		bool isFloat;
		dstring buffer;
		for(;;) {
			dchar symbol = get();

			if(symbol >= '0' && symbol <= '9')
				buffer ~= symbol;
			else if(symbol == '_') {
				// Do nothing, only cosmetic (e.g. 1_000_000).
			}
			else if(symbol == '.') {
				if(isFloat)
					break;
				isFloat = true;
				buffer ~= symbol;
			}
			else if(symbol == 'f') {
				isFloat = true;
				break;
			}
			else {
				if(current)
					current --;
				break;
			}

			current ++;

			if(current >= text.length)
				break;
		}

		lex.textLength = cast(uint)buffer.length;

		if(isFloat) {
			lex.type = GrLexemeType.float_;
			lex.fvalue = to!float(buffer);
		}
		else {
			lex.type = GrLexemeType.integer;
			lex.ivalue = to!int(buffer);
		}
		lexemes ~= lex;
	}

	/**
	Scan a `"` delimited string.
	*/
	void scanString() {
		GrLexeme lex = GrLexeme(this);
		lex.type = GrLexemeType.string_;
		lex.isLiteral = true;

		if(get() != '\"')
			raiseError("Expected \'\"\' at the beginning of the string.");
		current ++;

		dstring buffer;
		for(;;) {
			if(current >= text.length)
				raiseError("Missing \'\"\' character.");
			const dchar symbol = get();
			if(symbol == '\n') {
				positionOfLine = current;
				line ++;
			}
			else if(symbol == '\"')
				break;

			buffer ~= symbol;
			current ++;
		}

		lex.textLength = cast(uint)buffer.length + 2u;
		lex.svalue = buffer;
		lexemes ~= lex;
	}

	/**
	Scan a symbol-based operator.
	*/
	void scanOperator() {
		GrLexeme lex = GrLexeme(this);
		lex.isOperator = true;

		switch(get()) {
			case '{':
				lex.type = GrLexemeType.leftCurlyBrace;
				break;
			case '}':
				lex.type = GrLexemeType.rightCurlyBrace;
				break;
			case '(':
				lex.type = GrLexemeType.leftParenthesis;
				break;
			case ')':
				lex.type = GrLexemeType.rightParenthesis;
				break;
			case '[':
				lex.type = GrLexemeType.leftBracket;
				break;
			case ']':
				lex.type = GrLexemeType.rightBracket;
				break;
			case '.':
				lex.type = GrLexemeType.period;
				break;
			case ';':
				lex.type = GrLexemeType.semicolon;
				break;
			case ':':
				lex.type = GrLexemeType.methodCall;
				break;
			case ',':
				lex.type = GrLexemeType.comma;
				break;
			case '^':
				lex.type = GrLexemeType.copy;
				break;
			case '@':
                lex.type = GrLexemeType.at;
                break;
            case '&':
                lex.type = GrLexemeType.pointer;
                break;
			case '~':
				lex.type = GrLexemeType.concatenate;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.concatenateAssign;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '+':
				lex.type = GrLexemeType.add;
				if(current + 1 >= text.length)
					break;
				switch(get(1)) {
					case '=':
						lex.type = GrLexemeType.addAssign;
						lex.textLength = 2;
						current ++;
						break;
					case '+':
						lex.type = GrLexemeType.increment;
						lex.textLength = 2;
						current ++;
						break;
					default:
						break;
				}
				break;
			case '-':
				lex.type = GrLexemeType.substract;
				if(current + 1 >= text.length)
					break;
				switch(get(1)) {
					case '=':
						lex.type = GrLexemeType.substractAssign;
						lex.textLength = 2;
						current ++;
						break;
					case '-':
						lex.type = GrLexemeType.decrement;
						lex.textLength = 2;
						current ++;
						break;
					default:
						break;
				}
				break;
			case '*':
				lex.type = GrLexemeType.multiply;
				if(current + 1 >= text.length)
					break;
				switch(get(1)) {
					case '=':
						lex.type = GrLexemeType.multiplyAssign;
						lex.textLength = 2;
						current ++;
						break;
					case '*':
						lex.type = GrLexemeType.power;
						lex.textLength = 2;
						current ++;
						if(current + 1 >= text.length)
							break;
						if(get(1) == '=') {
							lex.type = GrLexemeType.powerAssign;
							lex.textLength = 3;
							current ++;
						}
						break;
					default:
						break;
				}
				break;
			case '/':
				lex.type = GrLexemeType.divide;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.divideAssign;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '%':
				lex.type = GrLexemeType.remainder;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.remainderAssign;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '=':
				lex.type = GrLexemeType.assign;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.equal;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '<':
				lex.type = GrLexemeType.lesser;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.lesserOrEqual;
					lex.textLength = 2;
					current ++;
				}
				else if(get(1) == '-') {
					lex.type = GrLexemeType.send;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '>':
				lex.type = GrLexemeType.greater;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.greaterOrEqual;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '!':
				lex.type = GrLexemeType.not;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.notEqual;
					lex.textLength = 2;
					current ++;
				}
				break;
			default:
				raiseError("GrLexer: Invalid operator.");
		}

		lexemes ~= lex;
	}

	/**
	Scan a known keyword or an identifier otherwise.
	*/
	void scanWord() {
		GrLexeme lex = GrLexeme(this);
		lex.isKeyword = true;

		dstring buffer;
		for(;;) {
			if(current >= text.length)
				break;

			const dchar symbol = get();
			if(symbol == '!' || symbol == '?') {
				buffer ~= symbol;
				current ++;
				break;
			}
			if(symbol <= '&' ||
				(symbol >= '(' && symbol <= '/') ||
				(symbol >= ':' && symbol <= '@') ||
				(symbol >= '[' && symbol <= '^') ||
				(symbol >= '{' && symbol <= 0x7F))
				break;

			buffer ~= symbol;
			current ++;
		}
		current --;

		lex.textLength = cast(uint)buffer.length;

		switch(buffer) {
			case "use":
				scanUse();
				return;
			case "main":
				lex.type = GrLexemeType.main_;
				break;
            case "event":
				lex.type = GrLexemeType.event_;
				break;
            case "class":
				lex.type = GrLexemeType.class_;
				break;
            case "enum":
				lex.type = GrLexemeType.enum_;
				break;
			case "if":
				lex.type = GrLexemeType.if_;
				break;
            case "unless":
                lex.type = GrLexemeType.unless;
                break;
			case "else":
				lex.type = GrLexemeType.else_;
				break;
			case "switch":
				lex.type = GrLexemeType.switch_;
				break;
			case "select":
				lex.type = GrLexemeType.select;
				break;
			case "case":
				lex.type = GrLexemeType.case_;
				break;
			case "while":
				lex.type = GrLexemeType.while_;
				break;
			case "do":
				lex.type = GrLexemeType.do_;
				break;
			case "until":
				lex.type = GrLexemeType.until;
				break;
			case "for":
				lex.type = GrLexemeType.for_;
				break;
			case "loop":
				lex.type = GrLexemeType.loop;
				break;
			case "return":
				lex.type = GrLexemeType.return_;
				break;
			case "self":
				lex.type = GrLexemeType.self;
				break;
            case "kill":
				lex.type = GrLexemeType.kill;
				break;
			case "killall":
				lex.type = GrLexemeType.killAll;
				break;
			case "yield":
				lex.type = GrLexemeType.yield;
				break;
			case "break":
				lex.type = GrLexemeType.break_;
				break;
			case "continue":
				lex.type = GrLexemeType.continue_;
				break;
            case "as":
                lex.type = GrLexemeType.as;
                break;
            case "is":
                lex.type = GrLexemeType.is_;
                break;
            case "try":
                lex.type = GrLexemeType.try_;
                break;
            case "catch":
                lex.type = GrLexemeType.catch_;
                break;
            case "raise_":
                lex.type = GrLexemeType.raise_;
                break;
            case "defer":
                lex.type = GrLexemeType.defer;
                break;
			case "void":
				lex.type = GrLexemeType.voidType;
				lex.isType = true;
				break;
			case "task":
				lex.type = GrLexemeType.taskType;
				lex.isType = true;
				break;
			case "func":
				lex.type = GrLexemeType.functionType;
				lex.isType = true;
				break;
			case "int":
				lex.type = GrLexemeType.intType;
				lex.isType = true;
				break;
			case "float":
				lex.type = GrLexemeType.floatType;
				lex.isType = true;
				break;
			case "bool":
				lex.type = GrLexemeType.boolType;
				lex.isType = true;
				break;
			case "string":
				lex.type = GrLexemeType.stringType;
				lex.isType = true;
				break;
			case "array":
				lex.type = GrLexemeType.arrayType;
				lex.isType = true;
				break;
			case "chan":
				lex.type = GrLexemeType.chanType;
				lex.isType = true;
				break;
			case "new":
				lex.type = GrLexemeType.new_;
				lex.isType = false;
				break;
            case "let":
                lex.type = GrLexemeType.autoType;
                lex.isType = false;
                break;
			case "true":
				lex.type = GrLexemeType.boolean;
				lex.isKeyword = false;
				lex.isLiteral = true;
				lex.bvalue = true;
				break;
			case "false":
				lex.type = GrLexemeType.boolean;
				lex.isKeyword = false;
				lex.isLiteral = true;
				lex.bvalue = false;
				break;
			case "not":
				lex.type = GrLexemeType.not;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			case "and":
				lex.type = GrLexemeType.and;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			case "or":
				lex.type = GrLexemeType.or;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			case "xor":
				lex.type = GrLexemeType.xor;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			default:
				lex.isKeyword = false;
				lex.type = GrLexemeType.identifier;
				lex.svalue = buffer;
				break;
		}

		lexemes ~= lex;
	}

	/// Transform the path in your path system.
	private string convertPathToImport(string path) {
		import std.regex : replaceAll, regex;
		import std.path: dirSeparator;
		return replaceAll(path, regex(r"\\/|/|\\"), dirSeparator);
	}

	/// add a single file path delimited by `" "` to the import list.
	private void scanFilePath() {
		import std.path: dirName, buildNormalizedPath, absolutePath;

		if(get() != '\"')
			raiseError("Expected \'\"\' at the beginning of the import.");
		current ++;

		dstring buffer;
		for(;;) {
			if(current >= text.length)
				raiseError("Missing \'\"\' character.");
			const dchar symbol = get();
			if(symbol == '\n') {
				positionOfLine = current;
				line ++;
			}
			else if(symbol == '\"')
				break;

			buffer ~= symbol;
			current ++;
		}
		string filePath = to!string(buffer);
		filePath = buildNormalizedPath(dirName(to!string(file)), convertPathToImport(filePath));
		filePath = absolutePath(filePath);
		buffer = to!dstring(filePath);
		if(filesImported.canFind(buffer) || filesToImport.canFind(buffer))
			return;
		filesToImport ~= buffer;
	}

	/// Scan a `use` directive. \
	/// Syntax: \
	/// `use "FILEPATH"` or \
	/// `use { "FILEPATH1", "FILEPATH2", "FILEPATH3" }` \
	/// ___
	/// add a file to the list of files to import.
	void scanUse() {
		advance();

		// Multiple files import.
		if(get() == '{') {
			advance();
			bool isFirst = true;
			for(;;) {
				if(isFirst)
					isFirst = false;
				else if(get() == '\"')
					advance();
				else
					raiseError("Missing \'\"\' character.");
				// EOF
				if(current >= text.length)
					raiseError("Missing \'}\' after import list.");
				// End of the import list.
				if(get() == '}')
					break;
				// Scan
				scanFilePath();
			}
		}
		else {
			scanFilePath();
		}
	}

	private void raiseError(string message) {
		GrError error = new GrError;
		error.type = GrError.Type.lexer;

		error.message = message;
		error.info = "";

		if(lexemes.length) {
			GrLexeme lexeme = lexemes[$ - 1];
			error.filePath = to!string(lexeme.getFile());
			error.lineText = to!string(lexeme.getLine()).replace("\t", " ");
			error.line = lexeme.line + 1u; // By convention, the first line is 1, not 0.
			error.column = lexeme.column;
			error.textLength = lexeme.textLength;
		}
		else {
			error.filePath = to!string(file);
			error.lineText = to!string(lines[line]);
			error.line = line + 1u; // By convention, the first line is 1, not 0.
			error.column = current - positionOfLine;
			error.textLength = 0u;
		}

		throw new GrLexerException(error);
	}
}

/// Returns a displayable version of a token type.
dstring grGetPrettyLexemeType(GrLexemeType operator) {
    dstring[] lexemeTypeStrTable = [
        "[", "]", "(", ")", "{", "}",
        ".", ";", ":", "::", ",", "@", "&", "as", "is", "try", "catch", "raise", "defer",
        "=",
        "+=", "-=", "*=", "/=", "~=", "%=", "**=",
        "+", "-",
        "+", "-", "*", "/", "~", "%", "**",
        "==", "!=", ">=", ">", "<=", "<",
        "and", "or", "xor", "not",
        "++", "--",
        "identifier", "const_int", "const_float", "const_bool", "const_str",
        "main", "event", "class", "enum", "new", "copy", "send", "receive",
        "void", "int", "float", "bool", "string", "array", "var", "func", "task", "chan", "let",
        "if", "unless", "else", "switch", "select", "case", "while", "do", "until", "for", "loop", "return", "self",
		"kill", "killall", "yield", "break", "continue"
    ];
    return lexemeTypeStrTable[operator];
}

package final class GrLexerException: Exception {
    GrError error;

    /// Ctor
    this(GrError error_, string file = __FILE__, size_t line = __LINE__) {
        super(error_.message, file, line);
        error = error_;
    }
}