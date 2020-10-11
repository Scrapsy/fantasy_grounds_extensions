-- Dice rolling
function roll_dice(num, sides)
    local val = 0
    for i = 1, num do
        val = val + math.random(sides)
    end
    return val
end

-- Lexer
-- TODO: This should ideally be an enum or something, but whatever.
PARSER_TOKEN_UNKNOWN = 0
PARSER_TOKEN_INT = 1
PARSER_TOKEN_LEFT_BRACE = 2
PARSER_TOKEN_RIGHT_BRACE = 3
PARSER_TOKEN_COMMA = 4
PARSER_TOKEN_ADD = 5
PARSER_TOKEN_SUB = 6
PARSER_TOKEN_DIE = 7
PARSER_TOKEN_MUL = 8
PARSER_TOKEN_DIV = 9
PARSER_TOKEN_MIN = 10
PARSER_TOKEN_MAX = 11
PARSER_TOKEN_FLOOR = 12
PARSER_TOKEN_CEIL = 13
PARSER_TOKEN_COS = 14
PARSER_TOKEN_EOF = 15

function make_token(kind, val)
    local t = {};
    t.kind = kind;
    t.val = val
    return t;
end

function token_kind_string(kind)
    local table = {
        [PARSER_TOKEN_UNKNOWN] = "UNKNOWN",
        [PARSER_TOKEN_INT] = "Integer",
        [PARSER_TOKEN_LEFT_BRACE] = "(",
        [PARSER_TOKEN_RIGHT_BRACE] = ")",
        [PARSER_TOKEN_COMMA] = ",",
        [PARSER_TOKEN_ADD] = "+",
        [PARSER_TOKEN_SUB] = "-",
        [PARSER_TOKEN_DIE] = "d",
        [PARSER_TOKEN_MUL] = "mul",
        [PARSER_TOKEN_DIV] = "div",
        [PARSER_TOKEN_MIN] = "min",
        [PARSER_TOKEN_MAX] = "max",
        [PARSER_TOKEN_FLOOR] = "floor",
        [PARSER_TOKEN_CEIL] = "ceil",
        [PARSER_TOKEN_COS] = "cos",
        [PARSER_TOKEN_EOF] = "EOF"
    }
    return table[kind]
end

function string_char(string, index)
    local fake_lua_index = index + 1
    return string:sub(fake_lua_index, fake_lua_index)
end

function is_digit(char)
    assert(char:len() == 1)
    return char:match("%d") ~= nil
end

function is_alpha(char)
    assert(char:len() == 1)
    return char:match("%a") ~= nil
end

function make_lexer(stream)
    local i = 0
    local function next_token()
        local stream_end = stream:len()
        while i < stream_end do
            while string_char(stream, i) == " " do
                i = i + 1
                if i >= stream_end then
                    return make_token(PARSER_TOKEN_EOF)
                end
            end

            local c = string_char(stream, i)

            if is_digit(c) then
                local zero_charcode = string.byte("0")
                local val = 0
                while i < stream_end and is_digit(string_char(stream, i)) do
                    val = val * 10
                    val = val + stream:byte(i + 1) - zero_charcode
                    i = i + 1
                end
                local tok = make_token(PARSER_TOKEN_INT, val)
                return tok
            elseif is_alpha(c) then
                if stream:sub(i + 1, i + 3) == "min" then
                    i = i + 3
                    return make_token(PARSER_TOKEN_MIN)
                elseif stream:sub(i + 1, i + 3) == "max" then
                    i = i + 3
                    return make_token(PARSER_TOKEN_MAX)
                elseif stream:sub(i + 1, i + 3) == "mul" then
                    i = i + 3
                    return make_token(PARSER_TOKEN_MUL)
                elseif stream:sub(i + 1, i + 3) == "div" then
                    i = i + 3
                    return make_token(PARSER_TOKEN_DIV)
                elseif stream:sub(i + 1, i + 3) == "cos" then
                    i = i + 3
                    return make_token(PARSER_TOKEN_COS)
                elseif stream:sub(i + 1, i + 5) == "floor" then
                    i = i + 5
                    return make_token(PARSER_TOKEN_FLOOR)
                elseif stream:sub(i + 1, i + 4) == "ceil" then
                    i = i + 4
                    return make_token(PARSER_TOKEN_CEIL)
                elseif c == "d" then
                    i = i + 1
                    return make_token(PARSER_TOKEN_DIE)
                else
                    local word_end = stream:find("[^%a]", i + 1)
                    error("Unrecognized symbol: " .. stream:sub(i + 1, word_end - 1))
                end
            elseif c == "(" then
                i = i + 1
                return make_token(PARSER_TOKEN_LEFT_BRACE)
            elseif c == ")" then
                i = i + 1
                return make_token(PARSER_TOKEN_RIGHT_BRACE)
            elseif c == "+" then
                i = i + 1
                return make_token(PARSER_TOKEN_ADD)
            elseif c == "-" then
                i = i + 1
                return make_token(PARSER_TOKEN_SUB)
            elseif c == "," then
                i = i + 1
                return make_token(PARSER_TOKEN_COMMA)
            else
                error("Unrecognized symbol: " .. c)
            end
        end
        return make_token(PARSER_TOKEN_EOF)
    end

    local token = next_token()

    local function advance()
        token = next_token()
    end

    local lexer = {
        advance = advance,
        peek = function() return token end
    }
    return lexer
end

-- Parser
function is_token(token, kind)
    return token.kind == kind
end

function expect_token(lexer, kind)
    local token = lexer.peek()
    if token.kind ~= PARSER_TOKEN_EOF then
        lexer.advance()
    end

    if token.kind ~= kind then
        error("Expected " .. token_kind_string(kind) ..
            ", got " .. token_kind_string(token.kind))
    end
end

function match_token(lexer, kind)
    local token = lexer.peek()
    if is_token(token, kind) then
        lexer.advance()
        return true
    end
    return false
end

function parse_builtin_2args(lexer)
    lexer.advance()
    expect_token(lexer, PARSER_TOKEN_LEFT_BRACE)
    local left_hand = parse_add(lexer)
    expect_token(lexer, PARSER_TOKEN_COMMA)
    local right_hand = parse_add(lexer)
    expect_token(lexer, PARSER_TOKEN_RIGHT_BRACE)
    return left_hand, right_hand
end

function parse_builtin_1arg(lexer)
    lexer.advance()
    expect_token(lexer, PARSER_TOKEN_LEFT_BRACE)
    local val = parse_add(lexer)
    expect_token(lexer, PARSER_TOKEN_RIGHT_BRACE)
    return val
end

function parse_base(lexer)
    local tok = lexer.peek()
    if is_token(tok, PARSER_TOKEN_INT) then
        lexer.advance()
        return tok.val
    elseif is_token(tok, PARSER_TOKEN_MUL) then
        local left, right = parse_builtin_2args(lexer)
        return left * right
    elseif is_token(tok, PARSER_TOKEN_DIV) then
        local left, right = parse_builtin_2args(lexer)
        return left / right
    elseif is_token(tok, PARSER_TOKEN_MIN) then
        local left, right = parse_builtin_2args(lexer)
        return math.min(left, right)
    elseif is_token(tok, PARSER_TOKEN_MAX) then
        local left, right = parse_builtin_2args(lexer)
        return math.max(left, right)
    elseif is_token(tok, PARSER_TOKEN_FLOOR) then
        local val = parse_builtin_1arg(lexer)
        return math.floor(val)
    elseif is_token(tok, PARSER_TOKEN_CEIL) then
        local val = parse_builtin_1arg(lexer)
        return math.ceil(val)
    elseif is_token(tok, PARSER_TOKEN_COS) then
        local val = parse_builtin_1arg(lexer)
        return math.cos(val)
    elseif match_token(lexer, PARSER_TOKEN_LEFT_BRACE) then
        local val = parse_add(lexer)
        expect_token(lexer, PARSER_TOKEN_RIGHT_BRACE)
        return val
    end
    error("Expected a number, a variable or '(' - got " .. token_kind_string(tok.kind))
end

function parse_unary(lexer)
    if match_token(lexer, PARSER_TOKEN_SUB) then
        return -parse_unary(lexer)
    end
    if match_token(lexer, PARSER_TOKEN_ADD) then
        return parse_unary(lexer)
    end
    return parse_base(lexer)
end

function parse_die(lexer)
    local val = parse_unary(lexer)
    local tok = lexer.peek()
    if match_token(lexer, PARSER_TOKEN_DIE) then
        local num = val
        local sides = parse_base(lexer)
        if sides <= 0 then
            error("Number of sides for dice must be greater than zero.")
        end
        if num < 0 then
            val = -roll_dice(-num, sides)
        else
            val = roll_dice(num, sides)
        end
    end
    return val
end

function parse_add(lexer)
    local val = parse_die(lexer)
    local tok = lexer.peek()
    while is_token(tok, PARSER_TOKEN_ADD) or is_token(tok, PARSER_TOKEN_SUB) do
        local operator = tok
        lexer.advance()
        local rval = parse_die(lexer)
        if is_token(operator, PARSER_TOKEN_ADD) then
            val = val + rval
        else
            assert(is_token(operator, PARSER_TOKEN_SUB))
            val = val - rval
        end
        tok = lexer.peek()
    end
    return val
end

function parse_expr(lexer)
    local val = parse_add(lexer)
    expect_token(lexer, PARSER_TOKEN_EOF)
    return val
end

function evaluate(str)
    local lexer = make_lexer(str)
    return parse_expr(lexer)
end

-- Tests and stuff
function print_token(token)
    if token.kind == PARSER_TOKEN_INT then
        print("Integer: ", token.val)
    else
        print(token_kind_string(token.kind))
    end
end

function test_lexer()
    local stream = "1d20+mul(1, 1)-floor(div(123456789, 23))"
    local lexer = make_lexer(stream)
    local tok = lexer.peek()
    function nxt()
        lexer.advance()
        return lexer.peek()
    end
    assert(tok.kind == PARSER_TOKEN_INT)
    assert(tok.val == 1)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_DIE)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_INT)
    assert(tok.val == 20)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_ADD)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_MUL)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_LEFT_BRACE)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_INT)
    assert(tok.val == 1)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_COMMA)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_INT)
    assert(tok.val == 1)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_RIGHT_BRACE)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_SUB)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_FLOOR)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_LEFT_BRACE)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_DIV)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_LEFT_BRACE)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_INT)
    assert(tok.val == 123456789)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_COMMA)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_INT)
    assert(tok.val == 23)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_RIGHT_BRACE)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_RIGHT_BRACE)
    tok = nxt()
    assert(tok.kind == PARSER_TOKEN_EOF)
    print("Lexer tests passed")
end

function test_parser()
    local function do_test(expr, expected)
        lexer = make_lexer(expr)
        actual = parse_expr(lexer)
        assert(actual == expected)
    end

    do_test("1", 1)
    do_test("(1)", 1)
    do_test("-+1", -1) -- Guess lua can't parse -+1
    do_test("-1-2-3", -1-2-3)
    do_test("mul(1, 2)", 1*2)
    do_test("mul(2, 3)+div(4, 5)", 2*3+4/5)
    do_test("mul(mul(2, (3+4)), 5)", 2*(3+4)*5)
    do_test("mul(2, -3)", 2*-3)
    do_test("floor(div(5, 3))", math.floor(5 / 3))
    do_test("ceil(div(5, 3))", math.ceil(5 / 3))
    do_test("min(1, 1d2)", 1)
    do_test("max(10, 1d6)", 10)
    print("Parser tests passed")
end
