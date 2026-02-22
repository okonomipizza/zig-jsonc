pub const Token = @This();

pub const TokenKind = enum {
    lbrace, // {
    rbrace, // }
    lbracket, // [
    rbracket, // ]
    colon, // :
    comma, // ,

    // values
    string,
    number,
    true,
    false,
    null,

    // comment
    line_comment, // //...

    whitespace,
    newline,

    eof,
    invalid,
};

kind: TokenKind,
start: u32,
end: u32,

pub fn slice(self: Token, src: []const u8) []const u8 {
    return src[self.start..self.end];
}
