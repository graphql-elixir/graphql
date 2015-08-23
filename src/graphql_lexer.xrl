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

Rules.

{Ignored}           : skip_token.
{Punctuator}        : {token, {punctuator, TokenLine, TokenChars}}.
{Name}              : {token, {name, TokenLine, TokenChars}}.

% Token processing code

Erlang code.

% to_id([$#|Chars]) ->
%   Chars.

% to_class([$.|Chars]) ->
%   Chars.
