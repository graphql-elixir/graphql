Nonterminals
  Document
  Definitions Definition
  OperationDefinition
  OperationType
  SelectionSet
  Selections Selection
  Field
  Name.

Terminals
  '{' '}' 'query'
  name int_value float_value string_value.

Rootsymbol Document.

Document -> Definitions : '$1'.

Definitions -> Definition : ['$1'].
Definitions -> Definition Definitions : ['$1'|'$2'].

Definition -> OperationDefinition : '$1'.

OperationType -> 'query' : extract_atom('$1').

SelectionSet -> '{' Selections '}' : {'$2'}.

OperationDefinition -> SelectionSet : '$1'.
OperationDefinition -> OperationType Name SelectionSet : { '$1', '$2', '$3' }.

Selections -> Selection : ['$1'].
Selections -> Selection Selections : ['$1'|'$2'].

Selection -> Field : '$1'.

% Field -> Alias Name Arguments Directives SelectionSet : '$1'
Field -> Name : '$1'.
Field -> Name SelectionSet : {'$1', '$2'}.

Name -> name : extract_token('$1').
Name -> int_value : extract_token('$1').
Name -> float_value : extract_token('$1').
Name -> string_value : extract_token('$1').

Erlang code.

extract_atom({Value, _Line}) -> Value.
extract_token({_Token, _Line, Value}) -> Value.
