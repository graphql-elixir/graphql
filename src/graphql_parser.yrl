Nonterminals
  % Document
  % Definitions Definition
  %   OperationDefinition
  SelectionSet
  Selections Selection
  Field
  Name.

Terminals
  '{' '}'
  name int_value float_value string_value.

Rootsymbol SelectionSet.

% Document -> Definition.
% Definitions -> Definition : ['$1'].
% Definitions -> Definition Definitions : ['$1'|'$2'].
% Definition -> OperationDefinition.
% OperationDefinition -> SelectionSet.

SelectionSet -> '{' Selections '}' : {'$2'}.
SelectionSet -> Field : '$1'.

Selections -> Selection : ['$1'].
Selections -> Selection Selections : ['$1'|'$2'].

Selection -> Field : '$1'.

%Field -> Alias Name Arguments Directives SelectionSet : '$1'
Field -> Name : '$1'.
% Field -> Alias Name Arguments Directives SelectionSet : '$1'

Name -> name : extract_token('$1').
Name -> int_value : extract_token('$1').
Name -> float_value : extract_token('$1').
Name -> string_value : extract_token('$1').


% OperationType -> 'query'.
% OperationType -> 'mutation'.
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
