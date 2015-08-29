Nonterminals
  Document
  Definitions Definition
  OperationDefinition
  SelectionSet
  Selections Selection
  Field
  Name.

Terminals
  '{' '}'
  name int_value float_value string_value.

Rootsymbol Document.

Document -> Definitions : '$1'.

Definitions -> Definition : ['$1'].
Definitions -> Definition Definitions : ['$1'|'$2'].

Definition -> OperationDefinition : '$1'.

OperationDefinition -> SelectionSet : '$1'.

SelectionSet -> '{' Selections '}' : {'$2'}.

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

Erlang code.

extract_token({_Token, _Line, Value}) -> Value.
