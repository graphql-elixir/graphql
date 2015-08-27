% Describe AWK-like regex shortcuts to tokens

Definitions.

% Ignored tokens
WhiteSpace          = [\x{0009}\x{000B}\x{000C}\x{0020}\x{00A0}]
_LineTerminator     = \x{000A}\x{000D}\x{2028}\x{2029}
LineTerminator      = [{_LineTerminator}]
Comment             = #[^{_LineTerminator}]*
Comma               = ,
Ignored             = {WhiteSpace}|{LineTerminator}|{Comment}|{Comma}

% Lexical tokens
Punctuator          = [!$():=@\[\]{|}]|\.\.\.
Name                = [_A-Za-z][_0-9A-Za-z]*

% int
Digit               = [0-9]
NonZeroDigit        = [1-9]
NegativeSign        = -
IntegerPart         = {NegativeSign}?(0|{NonZeroDigit}{Digit}*)
IntValue            = {IntegerPart}

% float
FractionalPart      = \.{Digit}+
Sign                = [+\-]
ExponentIndicator   = [eE]
ExponentPart        = {ExponentIndicator}{Sign}?{Digit}+
FloatValue          = {IntegerPart}{FractionalPart}|{IntegerPart}{ExponentPart}|{IntegerPart}{FractionalPart}{ExponentPart}

% string
HexDigit            = [0-9A-Fa-f]
EscapedUnicode      = u{HexDigit}{HexDigit}{HexDigit}{HexDigit}
EscapedCharacter    = ["\\\/bfnrt]
StringCharacter     = ([^\"{_LineTerminator}]|\\{EscapedUnicode}|\\{EscapedCharacter})
StringValue         = "{StringCharacter}*"

Rules.

{Ignored}           : skip_token.
\{                  : {token, {'{', TokenLine}}.
\}                  : {token, {'}', TokenLine}}.
% {Punctuator}        : {token, {TokenChars, TokenLine}}.
{Name}              : {token, {name, TokenLine, TokenChars}}.
{IntValue}          : {token, {int_value, TokenLine, TokenChars}}.
{FloatValue}        : {token, {float_value, TokenLine, TokenChars}}.
{StringValue}       : {token, {string_value, TokenLine, TokenChars}}.

Erlang code.
