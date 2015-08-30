Nonterminals
  Document
  Definitions Definition
  OperationDefinition
  OperationType
  SelectionSet
  Selections Selection
  Field
  Alias
  Name
  Arguments ArgumentList Argument
  Value.

Terminals
  '{' '}' '(' ')' ':' 'query' 'mutation'
  name int_value float_value string_value.

Rootsymbol Document.

Document -> Definitions : '$1'.

Definitions -> Definition : ['$1'].
Definitions -> Definition Definitions : ['$1'|'$2'].

Definition -> OperationDefinition : '$1'.

OperationType -> 'query' : extract_atom('$1').
OperationType -> 'mutation' : extract_atom('$1').

SelectionSet -> '{' Selections '}' : {'$2'}.

OperationDefinition -> SelectionSet : '$1'.
OperationDefinition -> OperationType Name SelectionSet : { '$1', '$2', '$3' }.

Selections -> Selection : ['$1'].
Selections -> Selection Selections : ['$1'|'$2'].

Selection -> Field : '$1'.

% Field -> Alias(opt) Name Arguments(opt) Directives(opt) SelectionSet(opt) : '$1'
Field -> Name : '$1'.
Field -> Name SelectionSet : {'$1', '$2'}.
Field -> Name Arguments : {'$1', '$2'}.
Field -> Name Arguments SelectionSet : {'$1', '$2', '$3'}.
Field -> Alias Name : {'$1', '$2'}.
Field -> Alias Name Arguments : {'$1', '$2', '$3'}.
Field -> Alias Name SelectionSet : {'$1', '$2', '$3'}.
Field -> Alias Name Arguments SelectionSet : {'$1', '$2', '$3', '$4'}.

Alias -> Name ':' : '$1'.

Arguments -> '(' ArgumentList ')' : '$2'.
ArgumentList -> Argument : ['$1'].
ArgumentList -> Argument ArgumentList : ['$1'|'$2'].
Argument -> Name ':' Value : {'$1', '$3'}.

Name -> name : extract_token('$1').

Value -> int_value : extract_token('$1').
Value -> float_value : extract_token('$1').
Value -> string_value : extract_token('$1').

Erlang code.

extract_atom({Value, _Line}) -> Value.
extract_token({_Token, _Line, Value}) -> Value.
