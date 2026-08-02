module ddct.util.template;

import std.string;
import std.algorithm;
import std.file;
import std.path;
import std.conv;
import std.ascii;
import std.regex;
import std.typecons;

import ddct.datatype;
import ddct.path : Path;

@safe:

struct Val {
    enum Type { Null, Bool, Int, String, Spec, Sem, Bran, Comm, Array, Map }
    Type type;
    bool bVal;
    int iVal;
    string sVal;
    VersionSpecifier specVal;
    SemVer semVal;
    Branch branVal;
    Commit commVal;
    Val[] arrVal;
    Val[string] mapVal;

    this(Type t) { type = t; }
    this(bool b) { type = Type.Bool; bVal = b; }
    this(int i) { type = Type.Int; iVal = i; }
    this(string s) { type = Type.String; sVal = s; }
    this(VersionSpecifier v) { type = Type.Spec; specVal = v; }
    this(SemVer s) { type = Type.Sem; semVal = s; }
    this(Branch b) { type = Type.Bran; branVal = b; }
    this(Commit c) { type = Type.Comm; commVal = c; }
    this(Val[] a) { type = Type.Array; arrVal = a; }
    this(Val[string] m) { type = Type.Map; mapVal = m; }

    bool isNull() const { return type == Type.Null; }
    bool isBool() const { return type == Type.Bool; }
    bool isInt() const { return type == Type.Int; }
    bool isString() const { return type == Type.String; }

    bool toBool() const {
        final switch (type) {
            case Type.Null: return false;
            case Type.Bool: return bVal;
            case Type.Int: return iVal != 0;
            case Type.String: return sVal.length > 0;
            case Type.Spec: return !specVal.isNull();
            case Type.Sem: return true;
            case Type.Bran: return true;
            case Type.Comm: return true;
            case Type.Array: return arrVal.length > 0;
            case Type.Map: return mapVal.length > 0;
        }
    }

    string toString() const {
        final switch (type) {
            case Type.Null: return "";
            case Type.Bool: return bVal ? "1" : "";
            case Type.Int: return iVal.to!string;
            case Type.String: return sVal;
            case Type.Spec: return specVal.toString();
            case Type.Sem: return semVal.toString();
            case Type.Bran: return branVal.name;
            case Type.Comm: return commVal.id;
            case Type.Array:
                string s = "";
                foreach (i, v; arrVal) {
                    if (i > 0) s ~= ", ";
                    s ~= v.toString();
                }
                return s;
            case Type.Map: return "map";
        }
    }

    Val getMember(string name) const {
        if (type == Type.Spec) {
            if (name == "type") return Val(specVal.type.to!int);
            if (name == "branch") return Val(specVal.branch);
            if (name == "commit") return Val(specVal.commit);
            if (name == "semanticTag") return Val(specVal.semanticTag);
            if (name == "major") return Val(specVal.semanticTag.major); // direct delegation fallback
        } else if (type == Type.Sem) {
            if (name == "major") return Val(semVal.major);
            if (name == "minor") return semVal.minor.isNull ? Val(Type.Null) : Val(semVal.minor.get);
            if (name == "patch") return semVal.patch.isNull ? Val(Type.Null) : Val(semVal.patch.get);
        } else if (type == Type.Bran) {
            if (name == "name") return Val(branVal.name);
        } else if (type == Type.Comm) {
            if (name == "id") return Val(commVal.id);
        }
        return Val(Type.Null);
    }

    Val callMethod(string name, Val[] args) const {
        if (type == Type.Spec) {
            if (name == "isBranch") return Val(specVal.isBranch());
            if (name == "isCommit") return Val(specVal.isCommit());
            if (name == "isSemanticTag") return Val(specVal.isSemanticTag());
            if (name == "getValue") {
                final switch (specVal.type) {
                    case VersionSpecifierType::Null: return Val(Type.Null);
                    case VersionSpecifierType::Branch: return Val(specVal.branch);
                    case VersionSpecifierType::Commit: return Val(specVal.commit);
                    case VersionSpecifierType::SemanticTag: return Val(specVal.semanticTag);
                }
            }
        }
        return Val(Type.Null);
    }

    Val getIndex(Val index) const {
        if (type == Type.Map) {
            string k = index.toString();
            auto p = k in mapVal;
            return p ? *p : Val(Type.Null);
        } else if (type == Type.Array) {
            int idx = index.iVal;
            if (idx >= 0 && idx < arrVal.length) {
                return arrVal[idx];
            }
        }
        return Val(Type.Null);
    }
}

struct Token {
    enum Type {
        EOF, Identifier, Number, String, Variable,
        And, Or, EqEqEq, EqEq, NeEqEq, NeEq, Ge, Le, Arrow, LBracket, RBracket,
        Question, Colon, Not, Lt, Gt, LParen, RParen, Eq, Semicolon, Comma,
        LBrace, RBrace, Match, Isset, Implode, DoubleQuestion, Plus, Minus
    }
    Type type;
    string text;
    int line;
}

class Lexer {
    string src;
    size_t idx;
    int line;

    this(string src) {
        this.src = src;
        this.idx = 0;
        this.line = 1;
    }

    private char peek() const {
        if (idx >= src.length) return '\0';
        return src[idx];
    }

    private char next() {
        if (idx >= src.length) return '\0';
        char c = src[idx++];
        if (c == '\n') line++;
        return c;
    }

    Token nextToken() {
        while (idx < src.length) {
            char c = peek();
            if (isWhite(c)) {
                next();
                continue;
            }

            // comments
            if (c == '/' && idx + 1 < src.length && src[idx + 1] == '/') {
                next(); next();
                while (idx < src.length && peek() != '\n') next();
                continue;
            }
            if (c == '/' && idx + 1 < src.length && src[idx + 1] == '*') {
                next(); next();
                while (idx < src.length) {
                    if (peek() == '*' && idx + 1 < src.length && src[idx + 1] == '/') {
                        next(); next();
                        break;
                    }
                    next();
                }
                continue;
            }

            // numbers
            if (isDigit(c)) {
                string text = "";
                while (isDigit(peek())) text ~= next();
                return Token(Token.Type.Number, text, line);
            }

            // string literals
            if (c == '\'' || c == '"') {
                char quote = next();
                string text = "";
                while (idx < src.length && peek() != quote) {
                    char sc = next();
                    if (sc == '\\') {
                        if (idx < src.length) text ~= next();
                    } else {
                        text ~= sc;
                    }
                }
                next(); // consume ending quote
                return Token(Token.Type.String, text, line);
            }

            // variables starting with $
            if (c == '$') {
                next();
                string text = "";
                while (isAlphaNum(peek()) || peek() == '_') text ~= next();
                return Token(Token.Type.Variable, text, line);
            }

            // identifiers
            if (isAlpha(c) || c == '_') {
                string text = "";
                while (isAlphaNum(peek()) || peek() == '_') text ~= next();
                if (text == "match") return Token(Token.Type.Match, text, line);
                if (text == "isset") return Token(Token.Type.Isset, text, line);
                if (text == "implode") return Token(Token.Type.Implode, text, line);
                if (text == "true") return Token(Token.Type.Number, "1", line);
                if (text == "false") return Token(Token.Type.Number, "0", line);
                return Token(Token.Type.Identifier, text, line);
            }

            // multi character operators
            if (c == '=' && idx + 2 < src.length && src[idx .. idx+3] == "===") {
                next(); next(); next(); return Token(Token.Type.EqEqEq, "===", line);
            }
            if (c == '!' && idx + 2 < src.length && src[idx .. idx+3] == "!==") {
                next(); next(); next(); return Token(Token.Type.NeEqEq, "!==", line);
            }
            if (c == '=' && idx + 1 < src.length && src[idx .. idx+2] == "==") {
                next(); next(); return Token(Token.Type.EqEq, "==", line);
            }
            if (c == '!' && idx + 1 < src.length && src[idx .. idx+2] == "!=") {
                next(); next(); return Token(Token.Type.NeEq, "!=", line);
            }
            if (c == '>' && idx + 1 < src.length && src[idx .. idx+2] == ">=") {
                next(); next(); return Token(Token.Type.Ge, ">=", line);
            }
            if (c == '<' && idx + 1 < src.length && src[idx .. idx+2] == "<=") {
                next(); next(); return Token(Token.Type.Le, "<=", line);
            }
            if (c == '-' && idx + 1 < src.length && src[idx .. idx+2] == "->") {
                next(); next(); return Token(Token.Type.Arrow, "->", line);
            }
            if (c == '&' && idx + 1 < src.length && src[idx .. idx+2] == "&&") {
                next(); next(); return Token(Token.Type.And, "&&", line);
            }
            if (c == '|' && idx + 1 < src.length && src[idx .. idx+2] == "||") {
                next(); next(); return Token(Token.Type.Or, "||", line);
            }
            if (c == '=' && idx + 1 < src.length && src[idx .. idx+2] == "=>") {
                next(); next(); return Token(Token.Type.Arrow, "=>", line); // match case map operator
            }
            if (c == '?' && idx + 1 < src.length && src[idx .. idx+2] == "??") {
                next(); next(); return Token(Token.Type.DoubleQuestion, "??", line);
            }

            // single character operators
            char op = next();
            switch (op) {
                case '?': return Token(Token.Type.Question, "?", line);
                case ':': return Token(Token.Type.Colon, ":", line);
                case '!': return Token(Token.Type.Not, "!", line);
                case '<': return Token(Token.Type.Lt, "<", line);
                case '>': return Token(Token.Type.Gt, ">", line);
                case '(': return Token(Token.Type.LParen, "(", line);
                case ')': return Token(Token.Type.RParen, ")", line);
                case '[': return Token(Token.Type.LBracket, "[", line);
                case ']': return Token(Token.Type.RBracket, "]", line);
                case '{': return Token(Token.Type.LBrace, "{", line);
                case '}': return Token(Token.Type.RBrace, "}", line);
                case '=': return Token(Token.Type.Eq, "=", line);
                case ';': return Token(Token.Type.Semicolon, ";", line);
                case ',': return Token(Token.Type.Comma, ",", line);
                case '+': return Token(Token.Type.Plus, "+", line);
                case '-': return Token(Token.Type.Minus, "-", line);
                default: break;
            }
        }
        return Token(Token.Type.EOF, "", line);
    }
}

class Parser {
    Token[] tokens;
    size_t idx;
    Val[string] context;

    this(Token[] tokens, Val[string] context) {
        this.tokens = tokens;
        this.idx = 0;
        this.context = context;
    }

    private Token peek() {
        if (idx >= tokens.length) return Token(Token.Type.EOF, "", 0);
        return tokens[idx];
    }

    private Token next() {
        if (idx >= tokens.length) return Token(Token.Type.EOF, "", 0);
        return tokens[idx++];
    }

    private void consume(Token.Type type, string err) {
        if (peek().type != type) {
            throw new Exception("Parser Error on line " ~ peek().line.to!string ~ ": " ~ err);
        }
        next();
    }

    void executeStatements() {
        while (peek().type != Token.Type.EOF) {
            // Skip use declarations
            if (peek().type == Token.Type.Identifier && peek().text == "use") {
                next();
                while (peek().type != Token.Type.Semicolon && peek().type != Token.Type.EOF) next();
                if (peek().type == Token.Type.Semicolon) next();
                continue;
            }

            // Skip <?php opening tag
            if (peek().type == Token.Type.Lt && idx + 2 < tokens.length && tokens[idx+1].text == "?" && tokens[idx+2].text == "php") {
                next(); next(); next();
                continue;
            }

            // If statement
            if (peek().type == Token.Type.Identifier && peek().text == "if") {
                next();
                consume(Token.Type.LParen, "Expected '(' after 'if'");
                Val condVal = parseExpression();
                consume(Token.Type.RParen, "Expected ')' after condition");
                
                // check for optional colon (colon-based syntax)
                bool hasColon = false;
                if (peek().type == Token.Type.Colon) {
                    next();
                    hasColon = true;
                }

                bool cond = condVal.toBool();
                if (cond) {
                    executeBlock(hasColon, true);
                } else {
                    executeBlock(hasColon, false);
                }
                continue;
            }

            // Assignment
            if (peek().type == Token.Type.Variable) {
                string varName = next().text;
                bool isArrayAppend = false;
                Val indexKey;
                bool hasIndex = false;

                if (peek().type == Token.Type.LBracket) {
                    next();
                    if (peek().type == Token.Type.RBracket) {
                        next();
                        isArrayAppend = true;
                    } else {
                        indexKey = parseExpression();
                        consume(Token.Type.RBracket, "Expected ']'");
                        hasIndex = true;
                    }
                }

                consume(Token.Type.Eq, "Expected '=' in assignment");
                Val val = parseExpression();
                if (peek().type == Token.Type.Semicolon) next();

                if (isArrayAppend) {
                    auto p = varName in context;
                    Val[] arr;
                    if (p && p.type == Val.Type.Array) {
                        arr = p.arrVal;
                    }
                    arr ~= val;
                    context[varName] = Val(arr);
                } else if (hasIndex) {
                    auto p = varName in context;
                    Val[string] map;
                    if (p && p.type == Val.Type.Map) {
                        map = p.mapVal;
                    }
                    map[indexKey.toString()] = val;
                    context[varName] = Val(map);
                } else {
                    context[varName] = val;
                }
                continue;
            }

            // Skip anything else
            next();
        }
    }

    private void executeBlock(bool colonSyntax, bool evaluate) {
        int depth = 1;
        while (peek().type != Token.Type.EOF) {
            auto t = peek();
            if (colonSyntax) {
                if (t.type == Token.Type.Identifier && t.text == "endif") {
                    next();
                    if (peek().type == Token.Type.Semicolon) next();
                    break;
                }
                if (t.type == Token.Type.Identifier && t.text == "else") {
                    next();
                    if (peek().type == Token.Type.Colon) next();
                    evaluate = !evaluate; // toggle for else block
                    continue;
                }
                if (t.type == Token.Type.Identifier && t.text == "elseif") {
                    next();
                    consume(Token.Type.LParen, "Expected '(' after elseif");
                    Val condVal = parseExpression();
                    consume(Token.Type.RParen, "Expected ')'");
                    if (peek().type == Token.Type.Colon) next();
                    evaluate = evaluate ? false : condVal.toBool();
                    continue;
                }
            } else {
                if (t.type == Token.Type.LBrace) {
                    next();
                    depth++;
                    continue;
                }
                if (t.type == Token.Type.RBrace) {
                    next();
                    depth--;
                    if (depth == 0) break;
                    continue;
                }
            }

            if (evaluate) {
                // Execute current statement recursively (for nested assignments / actions)
                // To keep it simple, we only run assignments inside blocks
                if (peek().type == Token.Type.Variable) {
                    string varName = next().text;
                    bool isArrayAppend = false;
                    Val indexKey;
                    bool hasIndex = false;

                    if (peek().type == Token.Type.LBracket) {
                        next();
                        if (peek().type == Token.Type.RBracket) {
                            next();
                            isArrayAppend = true;
                        } else {
                            indexKey = parseExpression();
                            consume(Token.Type.RBracket, "Expected ']'");
                            hasIndex = true;
                        }
                    }

                    consume(Token.Type.Eq, "Expected '='");
                    Val val = parseExpression();
                    if (peek().type == Token.Type.Semicolon) next();

                    if (isArrayAppend) {
                        auto p = varName in context;
                        Val[] arr;
                        if (p && p.type == Val.Type.Array) arr = p.arrVal;
                        arr ~= val;
                        context[varName] = Val(arr);
                    } else if (hasIndex) {
                        auto p = varName in context;
                        Val[string] map;
                        if (p && p.type == Val.Type.Map) map = p.mapVal;
                        map[indexKey.toString()] = val;
                        context[varName] = Val(map);
                    } else {
                        context[varName] = val;
                    }
                } else {
                    next();
                }
            } else {
                next();
            }
        }
    }

    Val parseExpression() {
        return parseLogicalOr();
    }

    private Val parseLogicalOr() {
        Val val = parseLogicalAnd();
        while (peek().type == Token.Type.Or) {
            next();
            Val rhs = parseLogicalAnd();
            val = Val(val.toBool() || rhs.toBool());
        }
        return val;
    }

    private Val parseLogicalAnd() {
        Val val = parseEquality();
        while (peek().type == Token.Type.And) {
            next();
            Val rhs = parseEquality();
            val = Val(val.toBool() && rhs.toBool());
        }
        return val;
    }

    private Val parseEquality() {
        Val val = parseRelational();
        while (true) {
            auto t = peek();
            if (t.type == Token.Type.EqEq || t.type == Token.Type.EqEqEq) {
                next();
                Val rhs = parseRelational();
                val = Val(val.toString() == rhs.toString());
            } else if (t.type == Token.Type.NeEq || t.type == Token.Type.NeEqEq) {
                next();
                Val rhs = parseRelational();
                val = Val(val.toString() != rhs.toString());
            } else if (t.type == Token.Type.DoubleQuestion) {
                next();
                Val rhs = parseRelational();
                val = val.isNull ? rhs : val;
            } else {
                break;
            }
        }
        return val;
    }

    private Val parseRelational() {
        Val val = parseAdditive();
        while (true) {
            auto t = peek();
            if (t.type == Token.Type.Lt) {
                next();
                Val rhs = parseAdditive();
                val = Val(val.iVal < rhs.iVal);
            } else if (t.type == Token.Type.Gt) {
                next();
                Val rhs = parseAdditive();
                val = Val(val.iVal > rhs.iVal);
            } else if (t.type == Token.Type.Le) {
                next();
                Val rhs = parseAdditive();
                val = Val(val.iVal <= rhs.iVal);
            } else if (t.type == Token.Type.Ge) {
                next();
                Val rhs = parseAdditive();
                val = Val(val.iVal >= rhs.iVal);
            } else {
                break;
            }
        }
        return val;
    }

    private Val parseAdditive() {
        Val val = parseUnary();
        while (true) {
            auto t = peek();
            if (t.type == Token.Type.Plus) {
                next();
                Val rhs = parseUnary();
                val = Val(val.iVal + rhs.iVal);
            } else if (t.type == Token.Type.Minus) {
                next();
                Val rhs = parseUnary();
                val = Val(val.iVal - rhs.iVal);
            } else {
                break;
            }
        }
        return val;
    }

    private Val parseUnary() {
        if (peek().type == Token.Type.Not) {
            next();
            Val rhs = parseUnary();
            return Val(!rhs.toBool());
        }
        return parsePrimary();
    }

    private Val parsePrimary() {
        auto t = peek();
        if (t.type == Token.Type.Number) {
            next();
            return Val(t.text.to!int);
        }
        if (t.type == Token.Type.String) {
            next();
            return Val(t.text);
        }
        if (t.type == Token.Type.Variable) {
            next();
            auto p = t.text in context;
            Val baseVal = p ? *p : Val(Type.Null);
            return parseMemberOrIndex(baseVal);
        }
        if (t.type == Token.Type.Isset) {
            next();
            consume(Token.Type.LParen, "Expected '(' after isset");
            
            // Check variable inside isset
            bool isDefined = false;
            if (peek().type == Token.Type.Variable) {
                string vname = next().text;
                auto p = vname in context;
                if (p && !p.isNull) {
                    isDefined = true;
                    // handle optional array index inside isset: isset($extras['dub'])
                    if (peek().type == Token.Type.LBracket) {
                        next();
                        Val idxVal = parseExpression();
                        consume(Token.Type.RBracket, "Expected ']'");
                        if (p.type == Val.Type.Map) {
                            auto pSub = idxVal.toString() in p.mapVal;
                            isDefined = pSub && !pSub.isNull;
                        } else {
                            isDefined = false;
                        }
                    }
                }
            }
            consume(Token.Type.RParen, "Expected ')' after isset");
            return Val(isDefined);
        }
        if (t.type == Token.Type.Implode) {
            next();
            consume(Token.Type.LParen, "Expected '(' after implode");
            Val sep = parseExpression();
            consume(Token.Type.Comma, "Expected ',' in implode");
            Val arr = parseExpression();
            consume(Token.Type.RParen, "Expected ')'");
            string s = "";
            if (arr.type == Val.Type.Array) {
                foreach (i, item; arr.arrVal) {
                    if (i > 0) s ~= sep.toString();
                    s ~= item.toString();
                }
            }
            return Val(s);
        }
        if (t.type == Token.Type.Match) {
            next();
            consume(Token.Type.LParen, "Expected '(' in match");
            Val matchVal = parseExpression();
            consume(Token.Type.RParen, "Expected ')'");
            consume(Token.Type.LBrace, "Expected '{' in match block");
            
            Val matchedResult = Val(Type.Null);
            bool found = false;
            
            while (peek().type != Token.Type.RBrace && peek().type != Token.Type.EOF) {
                // match arms: VersionSpecifierType::SemanticTag => ...
                // or default => ...
                // read patterns
                Val[] patterns;
                while (true) {
                    if (peek().text == "default") {
                        next();
                        patterns ~= Val("default");
                    } else if (peek().type == Token.Type.Identifier && peek().text == "VersionSpecifierType") {
                        next();
                        next(); // skip ::
                        string member = next().text;
                        // Map it to specifier type values (SemanticTag = 3, Branch = 1, Commit = 2, Null = 0)
                        int typVal = 0;
                        if (member == "SemanticTag") typVal = 3; // VersionSpecifierType.SemanticTag is 3
                        else if (member == "Branch") typVal = 1;
                        else if (member == "Commit") typVal = 2;
                        patterns ~= Val(typVal);
                    } else {
                        patterns ~= parseExpression();
                    }
                    if (peek().type == Token.Type.Comma) {
                        next();
                        continue;
                    }
                    break;
                }
                
                consume(Token.Type.Arrow, "Expected '=>'");
                Val armVal = parseExpression();
                if (peek().type == Token.Type.Comma) next();
                if (peek().type == Token.Type.Semicolon) next();
                
                if (!found) {
                    foreach (pat; patterns) {
                        if (pat.toString() == "default" || pat.toString() == matchVal.toString()) {
                            matchedResult = armVal;
                            found = true;
                            break;
                        }
                    }
                }
            }
            consume(Token.Type.RBrace, "Expected '}'");
            return matchedResult;
        }
        if (t.type == Token.Type.LParen) {
            next();
            
            // Check for dynamic closure / IIFE: (function () use ($semver) { ... })()
            if (peek().type == Token.Type.Identifier && peek().text == "function") {
                next();
                consume(Token.Type.LParen, "Expected '('");
                consume(Token.Type.RParen, "Expected ')'");
                if (peek().type == Token.Type.Identifier && peek().text == "use") {
                    next();
                    consume(Token.Type.LParen, "Expected '('");
                    while (peek().type != Token.Type.RParen && peek().type != Token.Type.EOF) next();
                    consume(Token.Type.RParen, "Expected ')'");
                }
                consume(Token.Type.LBrace, "Expected '{'");
                
                // Evaluate IIFE body by parsing statements until return
                Val resultVal = Val(Type.Null);
                while (peek().type != Token.Type.RBrace && peek().type != Token.Type.EOF) {
                    if (peek().type == Token.Type.Identifier && peek().text == "if") {
                        next();
                        consume(Token.Type.LParen, "Expected '('");
                        Val cond = parseExpression();
                        consume(Token.Type.RParen, "Expected ')'");
                        
                        // We assume single return statement inside if block for these specific IIFEs
                        if (peek().type == Token.Type.LBrace) next();
                        if (peek().type == Token.Type.Identifier && peek().text == "return") {
                            next();
                            Val ret = parseExpression();
                            if (peek().type == Token.Type.Semicolon) next();
                            if (cond.toBool()) {
                                resultVal = ret;
                                break;
                            }
                        }
                        if (peek().type == Token.Type.RBrace) next();
                    } else if (peek().type == Token.Type.Identifier && peek().text == "return") {
                        next();
                        resultVal = parseExpression();
                        if (peek().type == Token.Type.Semicolon) next();
                        break;
                    } else {
                        next();
                    }
                }
                
                // skip rest of closure
                while (peek().type != Token.Type.RBrace && peek().type != Token.Type.EOF) next();
                consume(Token.Type.RBrace, "Expected '}'");
                consume(Token.Type.RParen, "Expected ')'");
                consume(Token.Type.LParen, "Expected '('");
                consume(Token.Type.RParen, "Expected ')'");
                return resultVal;
            }
            
            Val val = parseExpression();
            consume(Token.Type.RParen, "Expected ')'");
            return parseMemberOrIndex(val);
        }
        
        return Val(Type.Null);
    }

    private Val parseMemberOrIndex(Val baseVal) {
        while (true) {
            if (peek().type == Token.Type.Arrow) {
                next();
                consume(Token.Type.Identifier, "Expected member name");
                string member = tokens[idx-1].text;
                if (peek().type == Token.Type.LParen) {
                    next();
                    Val[] args;
                    while (peek().type != Token.Type.RParen && peek().type != Token.Type.EOF) {
                        args ~= parseExpression();
                        if (peek().type == Token.Type.Comma) next();
                    }
                    consume(Token.Type.RParen, "Expected ')'");
                    baseVal = baseVal.callMethod(member, args);
                } else {
                    baseVal = baseVal.getMember(member);
                }
            } else if (peek().type == Token.Type.LBracket) {
                next();
                Val index = parseExpression();
                consume(Token.Type.RBracket, "Expected ']'");
                baseVal = baseVal.getIndex(index);
            } else {
                break;
            }
        }
        return baseVal;
    }
}

class TemplateEngine {
    private string templatesDir;
    private string[] renderingStack;

    this(string templatesDir) {
        this.templatesDir = templatesDir;
    }

    // Dynamic templates root security sandbox check
    private string validateAndGetTemplatePath(string templateName) const @trusted {
        import std.path : canonicalPath, absolutePath, dirSeparator;
        import std.algorithm : startsWith;

        string templatesBase = canonicalPath(absolutePath(templatesDir));
        string resolvedTpl = canonicalPath(absolutePath(templatesBase ~ dirSeparator ~ templateName));
        
        if (!resolvedTpl.startsWith(templatesBase ~ dirSeparator)) {
            throw new Exception("Security Violation: Path traversal detected in template include path: " ~ templateName);
        }

        return resolvedTpl;
    }

    string render(string templateName, Val[string] initialContext) {
        // cyclic check
        if (renderingStack.canFind(templateName)) {
            throw new Exception("Security Violation: Cyclic template include detected: " ~ templateName);
        }
        // recursion limit check
        if (renderingStack.length >= 15) {
            throw new Exception("Security Violation: Template recursion limit exceeded at include: " ~ templateName);
        }

        renderingStack ~= templateName;
        scope(exit) renderingStack.length--;

        string fullPath = validateAndGetTemplatePath(templateName);
        string content = readText(fullPath);

        // AST engine logic
        return processTemplateContent(content, initialContext);
    }

    private string processTemplateContent(string content, ref Val[string] context) {
        string result = "";
        size_t idx = 0;

        while (idx < content.length) {
            ptrdiff_t openIdx = content[idx .. $].indexOf("{{");
            if (openIdx == -1) {
                result ~= content[idx .. $];
                break;
            }

            result ~= content[idx .. idx + openIdx];
            idx += openIdx;

            ptrdiff_t closeIdx = content[idx .. $].indexOf("}}");
            if (closeIdx == -1) {
                throw new Exception("Template Syntax Error: Missing closing tag '}}'");
            }

            string tag = content[idx + 2 .. idx + closeIdx].strip();
            idx += closeIdx + 2;

            if (tag.startsWith("#")) {
                // Control statement
                string control = tag[1 .. $].strip();
                
                if (control.startsWith("if")) {
                    string exprStr = control[2 .. $].strip();
                    if (exprStr.endsWith(":")) exprStr = exprStr[0 .. $-1].strip();
                    if (exprStr.startsWith("(") && exprStr.endsWith(")")) exprStr = exprStr[1 .. $-1].strip();

                    Val cond = evaluateExpression(exprStr, context);
                    
                    // Consume until endif / else / elseif
                    int ifDepth = 1;
                    string innerContent = "";
                    bool foundBranch = false;
                    bool active = cond.toBool();

                    while (idx < content.length) {
                        ptrdiff_t subOpen = content[idx .. $].indexOf("{{#");
                        if (subOpen == -1) break;
                        
                        ptrdiff_t subClose = content[idx + subOpen .. $].indexOf("}}");
                        if (subClose == -1) break;

                        string subTag = content[idx + subOpen + 3 .. idx + subOpen + subClose].strip();
                        
                        if (subTag.startsWith("if")) {
                            ifDepth++;
                        } else if (subTag.startsWith("endif")) {
                            ifDepth--;
                            if (ifDepth == 0) {
                                if (active && !foundBranch) {
                                    innerContent ~= content[idx .. idx + subOpen];
                                }
                                idx += subOpen + subClose + 3;
                                break;
                            }
                        } else if (ifDepth == 1 && subTag.startsWith("else")) {
                            if (active && !foundBranch) {
                                innerContent ~= content[idx .. idx + subOpen];
                                foundBranch = true;
                            }
                            active = !foundBranch;
                            idx += subOpen + subClose + 3;
                            continue;
                        } else if (ifDepth == 1 && subTag.startsWith("elseif")) {
                            if (active && !foundBranch) {
                                innerContent ~= content[idx .. idx + subOpen];
                                foundBranch = true;
                            }
                            string subExpr = subTag[6 .. $].strip();
                            if (subExpr.endsWith(":")) subExpr = subExpr[0 .. $-1].strip();
                            if (subExpr.startsWith("(") && subExpr.endsWith(")")) subExpr = subExpr[1 .. $-1].strip();
                            Val nextCond = evaluateExpression(subExpr, context);
                            active = !foundBranch && nextCond.toBool();
                            idx += subOpen + subClose + 3;
                            continue;
                        }

                        if (active) {
                            innerContent ~= content[idx .. idx + subOpen + subClose + 2];
                        }
                        idx += subOpen + subClose + 2;
                    }
                    result ~= processTemplateContent(innerContent, context);
                } else {
                    // Inline evaluation e.g. assignment: $buildStage = 'build-stage';
                    evaluateStatements(control, context);
                }
            } else if (tag.startsWith("<")) {
                // Inclusion tag: {{< path }}
                string includePath = tag[1 .. $].strip();
                
                // If it is a php variable file, we evaluate it directly into context
                if (includePath.endsWith(".php")) {
                    string phpPath = validateAndGetTemplatePath(includePath);
                    string phpContent = readText(phpPath);
                    evaluateStatements(phpContent, context);
                } else {
                    result ~= render(includePath, context);
                }
            } else {
                // Variable printing tag: {{ $variable }}
                Val val = evaluateExpression(tag, context);
                string strVal = val.toString();

                // Instruction injection mitigation: reject newline injections inside standard interpolated variables
                if (strVal.indexOf('\n') != -1 || strVal.indexOf('\r') != -1) {
                    throw new Exception("Security Violation: Newline injection detected during template variable rendering: " ~ tag);
                }

                result ~= strVal;
            }
        }
        return result;
    }

    private Val evaluateExpression(string exprStr, ref Val[string] context) {
        auto lexer = new Lexer(exprStr);
        Token[] tokens;
        while (true) {
            auto t = lexer.nextToken();
            tokens ~= t;
            if (t.type == Token.Type.EOF) break;
        }
        auto parser = new Parser(tokens, context);
        return parser.parseExpression();
    }

    private void evaluateStatements(string stmtsStr, ref Val[string] context) {
        auto lexer = new Lexer(stmtsStr);
        Token[] tokens;
        while (true) {
            auto t = lexer.nextToken();
            tokens ~= t;
            if (t.type == Token.Type.EOF) break;
        }
        auto parser = new Parser(tokens, context);
        parser.executeStatements();
        
        // update main context map
        foreach (k, v; parser.context) {
            context[k] = v;
        }
    }
}
