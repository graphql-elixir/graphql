% Describe AWK-like regex shortcuts to tokens

Definitions.

WhiteSpace          = [\x{0009}\x{000B}\x{000C}\x{0020}\x{00A0}]
_LineTerminator     = \x{000A}\x{000D}\x{2028}\x{2029}
LineTerminator      = [{_LineTerminator}]
Comment             = #[^{_LineTerminator}]*
Comma               = ,
Ignored             = {WhiteSpace}|{LineTerminator}|{Comment}|{Comma}

% Describe how tokens are generated

Rules.

% {Word}          : {token, {word, TokenLine, TokenChars}}.
{Ignored}           : skip_token.

% Token processing code

Erlang code.

% to_id([$#|Chars]) ->
%   Chars.

% to_class([$.|Chars]) ->
%   Chars.
