Nonterminals Document Definition OperationType.
Terminals OperationType.
Rootsymbol Document.

% OperationType -> 'query'.
% OperationType -> 'mutation'.
%
% S
%
% ListValue -> '[' ']'       : [].
% ListValue -> '[' elems ']' : '$2'.

% list -> '[' ']'       : [].
% list -> '[' elems ']' : '$2'.
%
% elems -> elem           : ['$1'].
% elems -> elem ',' elems : ['$1'|'$3'].
%
% elem -> int  : extract_token('$1').
% elem -> atom : extract_token('$1').
% elem -> list : '$1'.

Erlang code.

extract_token({_Token, _Line, Value}) -> Value.
