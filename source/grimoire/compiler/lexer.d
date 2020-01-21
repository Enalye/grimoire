/**
Scan a file and produce a list of tokens.

Copyright: (c) Enalye 2018
License: Zlib
Authors: Enalye
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
	LeftBracket, RightBracket, LeftParenthesis, RightParenthesis, LeftCurlyBrace, RightCurlyBrace,
	Period, Semicolon, Colon, MethodCall, Comma, At, Pointer, As, Is, Try, Catch, Raise, Defer,
	Assign,
	AddAssign, SubstractAssign, MultiplyAssign, DivideAssign, ConcatenateAssign, RemainderAssign, PowerAssign,
	Plus, Minus,
	Add, Substract, Multiply, Divide, Concatenate, Remainder, Power,
	Equal, NotEqual, GreaterOrEqual, Greater, LesserOrEqual, Lesser,
	And, Or, Xor, Not,
	Increment, Decrement,
	Identifier, Integer, Float, Boolean, String,
	Main, Event, Object, Tuple, New, Copy, Send, Receive,
	VoidType, IntType, FloatType, BoolType, StringType, ArrayType, FunctionType, TaskType, ChanType, AutoType,
	If, Unless, Else, Switch, Select, Case, While, Do, Until, For, Loop, Return, Self,
	Kill, KillAll, Yield, Break, Continue,
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
	GrLexer lexer;

	uint fileId;

    /// Position information in case of errors.
	uint line, column, textLength = 1;

	GrLexemeType type;

    /// Whether the lexeme is a constant value.
	bool isLiteral;

    /// Whether the lexeme is an operator.
	bool isOperator;

    /// Is this a reserved grimoire word ?
	bool isKeyword;

    /// Only describe first class type such as `int`, `string` or `func`.
    /// Structure or other custom type are not.
	bool isType;

    /// Integral value of the constant.
    /// isLiteral will be true and type set to Integer.
	int ivalue;

    /// Floating point value of the constant.
    /// isLiteral will be true and type set to Float.
	float fvalue;

    /// Boolean value of the constant.
    /// isLiteral will be true and type set to Boolean.
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
				case ':': .. case '>':
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
			lex.type = GrLexemeType.Float;
			lex.fvalue = to!float(buffer);
		}
		else {
			lex.type = GrLexemeType.Integer;
			lex.ivalue = to!int(buffer);
		}
		lexemes ~= lex;
	}

	/**
	Scan a `"` delimited string.
	*/
	void scanString() {
		GrLexeme lex = GrLexeme(this);
		lex.type = GrLexemeType.String;
		lex.isLiteral = true;

		if(get() != '\"')
			raiseError("Expected \'\"\' at the beginning of the string.");
		current ++;

		dstring buffer;
		for(;;) {
			if(current >= text.length)
				raiseError("Missing \'\"\' character.");
			dchar symbol = get();
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
				lex.type = GrLexemeType.LeftCurlyBrace;
				break;
			case '}':
				lex.type = GrLexemeType.RightCurlyBrace;
				break;
			case '(':
				lex.type = GrLexemeType.LeftParenthesis;
				break;
			case ')':
				lex.type = GrLexemeType.RightParenthesis;
				break;
			case '[':
				lex.type = GrLexemeType.LeftBracket;
				break;
			case ']':
				lex.type = GrLexemeType.RightBracket;
				break;
			case '.':
				lex.type = GrLexemeType.Period;
				break;
			case ';':
				lex.type = GrLexemeType.Semicolon;
				break;
			case ':':
				lex.type = GrLexemeType.Colon;
				if(current + 1 >= text.length)
					break;
				if(get(1) == ':') {
					lex.type = GrLexemeType.MethodCall;
					lex.textLength = 2;
					current ++;
				}
				break;
			case ',':
				lex.type = GrLexemeType.Comma;
				break;
			case '^':
				lex.type = GrLexemeType.Copy;
				break;
			case '@':
                lex.type = GrLexemeType.At;
                break;
            case '&':
                lex.type = GrLexemeType.Pointer;
                break;
			case '~':
				lex.type = GrLexemeType.Concatenate;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.ConcatenateAssign;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '+':
				lex.type = GrLexemeType.Add;
				if(current + 1 >= text.length)
					break;
				switch(get(1)) {
					case '=':
						lex.type = GrLexemeType.AddAssign;
						lex.textLength = 2;
						current ++;
						break;
					case '+':
						lex.type = GrLexemeType.Increment;
						lex.textLength = 2;
						current ++;
						break;
					default:
						break;
				}
				break;
			case '-':
				lex.type = GrLexemeType.Substract;
				if(current + 1 >= text.length)
					break;
				switch(get(1)) {
					case '=':
						lex.type = GrLexemeType.SubstractAssign;
						lex.textLength = 2;
						current ++;
						break;
					case '-':
						lex.type = GrLexemeType.Decrement;
						lex.textLength = 2;
						current ++;
						break;
					default:
						break;
				}
				break;
			case '*':
				lex.type = GrLexemeType.Multiply;
				if(current + 1 >= text.length)
					break;
				switch(get(1)) {
					case '=':
						lex.type = GrLexemeType.MultiplyAssign;
						lex.textLength = 2;
						current ++;
						break;
					case '*':
						lex.type = GrLexemeType.Power;
						lex.textLength = 2;
						current ++;
						if(current + 1 >= text.length)
							break;
						if(get(1) == '=') {
							lex.type = GrLexemeType.PowerAssign;
							lex.textLength = 3;
							current ++;
						}
						break;
					default:
						break;
				}
				break;
			case '/':
				lex.type = GrLexemeType.Divide;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.DivideAssign;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '%':
				lex.type = GrLexemeType.Remainder;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.RemainderAssign;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '=':
				lex.type = GrLexemeType.Assign;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.Equal;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '<':
				lex.type = GrLexemeType.Lesser;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.LesserOrEqual;
					lex.textLength = 2;
					current ++;
				}
				else if(get(1) == '-') {
					lex.type = GrLexemeType.Send;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '>':
				lex.type = GrLexemeType.Greater;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.GreaterOrEqual;
					lex.textLength = 2;
					current ++;
				}
				break;
			case '!':
				lex.type = GrLexemeType.Not;
				if(current + 1 >= text.length)
					break;
				if(get(1) == '=') {
					lex.type = GrLexemeType.NotEqual;
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
			if(symbol <= '&' || (symbol >= '(' && symbol <= '/') || (symbol >= ':' && symbol <= '>') || (symbol == '@') || (symbol >= '[' && symbol <= '^') || (symbol >= '{' && symbol <= 0x7F))
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
				lex.type = GrLexemeType.Main;
				break;
            case "event":
				lex.type = GrLexemeType.Event;
				break;
            case "object":
				lex.type = GrLexemeType.Object;
				break;
            case "tuple":
				lex.type = GrLexemeType.Tuple;
				break;
			case "if":
				lex.type = GrLexemeType.If;
				break;
            case "unless":
                lex.type = GrLexemeType.Unless;
                break;
			case "else":
				lex.type = GrLexemeType.Else;
				break;
			case "switch":
				lex.type = GrLexemeType.Switch;
				break;
			case "select":
				lex.type = GrLexemeType.Select;
				break;
			case "case":
				lex.type = GrLexemeType.Case;
				break;
			case "while":
				lex.type = GrLexemeType.While;
				break;
			case "do":
				lex.type = GrLexemeType.Do;
				break;
			case "until":
				lex.type = GrLexemeType.Until;
				break;
			case "for":
				lex.type = GrLexemeType.For;
				break;
			case "loop":
				lex.type = GrLexemeType.Loop;
				break;
			case "return":
				lex.type = GrLexemeType.Return;
				break;
			case "self":
				lex.type = GrLexemeType.Self;
				break;
            case "kill":
				lex.type = GrLexemeType.Kill;
				break;
			case "killall":
				lex.type = GrLexemeType.KillAll;
				break;
			case "yield":
				lex.type = GrLexemeType.Yield;
				break;
			case "break":
				lex.type = GrLexemeType.Break;
				break;
			case "continue":
				lex.type = GrLexemeType.Continue;
				break;
            case "as":
                lex.type = GrLexemeType.As;
                break;
            case "is":
                lex.type = GrLexemeType.Is;
                break;
            case "try":
                lex.type = GrLexemeType.Try;
                break;
            case "catch":
                lex.type = GrLexemeType.Catch;
                break;
            case "raise":
                lex.type = GrLexemeType.Raise;
                break;
            case "defer":
                lex.type = GrLexemeType.Defer;
                break;
			case "void":
				lex.type = GrLexemeType.VoidType;
				lex.isType = true;
				break;
			case "task":
				lex.type = GrLexemeType.TaskType;
				lex.isType = true;
				break;
			case "func":
				lex.type = GrLexemeType.FunctionType;
				lex.isType = true;
				break;
			case "int":
				lex.type = GrLexemeType.IntType;
				lex.isType = true;
				break;
			case "float":
				lex.type = GrLexemeType.FloatType;
				lex.isType = true;
				break;
			case "bool":
				lex.type = GrLexemeType.BoolType;
				lex.isType = true;
				break;
			case "string":
				lex.type = GrLexemeType.StringType;
				lex.isType = true;
				break;
			case "array":
				lex.type = GrLexemeType.ArrayType;
				lex.isType = true;
				break;
			case "chan":
				lex.type = GrLexemeType.ChanType;
				lex.isType = true;
				break;
			case "new":
				lex.type = GrLexemeType.New;
				lex.isType = false;
				break;
            case "let":
                lex.type = GrLexemeType.AutoType;
                lex.isType = false;
                break;
			case "true":
				lex.type = GrLexemeType.Boolean;
				lex.isKeyword = false;
				lex.isLiteral = true;
				lex.bvalue = true;
				break;
			case "false":
				lex.type = GrLexemeType.Boolean;
				lex.isKeyword = false;
				lex.isLiteral = true;
				lex.bvalue = false;
				break;
			case "not":
				lex.type = GrLexemeType.Not;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			case "and":
				lex.type = GrLexemeType.And;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			case "or":
				lex.type = GrLexemeType.Or;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			case "xor":
				lex.type = GrLexemeType.Xor;
				lex.isKeyword = false;
				lex.isOperator = true;
				break;
			default:
				lex.isKeyword = false;
				lex.type = GrLexemeType.Identifier;
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

	/// Add a single file path delimited by `" "` to the import list.
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
	/// Add a file to the list of files to import.
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
        "main", "event", "object", "tuple", "new", "copy", "send", "receive",
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