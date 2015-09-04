Nonterminals
  Document
  Definitions Definition
  OperationDefinition
  OperationType
  SelectionSet
  Selections Selection
  FragmentSpread FragmentName
  FragmentDefinition
  InlineFragment
  Directives Directive
  Field
  Alias
  Name
  Arguments ArgumentList Argument
  VariableDefinitionList
  VariableDefinitions VariableDefinition
  Variable
  DefaultValue
  Type
  TypeCondition
  NamedType ListType NonNullType
  Value.

Terminals
  '{' '}' '(' ')' '[' ']' '!' ':' '@' '$' '=' '...' 'query' 'mutation' 'fragment' 'on'
  name int_value float_value string_value boolean_value.

Rootsymbol Document.

Document -> Definitions : '$1'.

Definitions -> Definition : ['$1'].
Definitions -> Definition Definitions : ['$1'|'$2'].

Definition -> OperationDefinition : '$1'.
Definition -> FragmentDefinition : '$1'.

OperationType -> 'query' : extract_atom('$1').
OperationType -> 'mutation' : extract_atom('$1').

SelectionSet -> '{' Selections '}' : {'$2'}.

OperationDefinition -> SelectionSet : '$1'.
OperationDefinition -> OperationType Name SelectionSet : { '$1', '$2', '$3' }.
OperationDefinition -> OperationType Name VariableDefinitions SelectionSet : { '$1', '$2', '$3', '$4' }.
OperationDefinition -> OperationType Name Directives SelectionSet : { '$1', '$2', '$3', '$4' }.
OperationDefinition -> OperationType Name VariableDefinitions Directives SelectionSet : { '$1', '$2', '$3', '$4', '$5' }.

FragmentDefinition -> 'fragment' FragmentName 'on' TypeCondition SelectionSet : {extract_atom('$1'), '$2', extract_atom('$3'), '$4', '$5'}.
FragmentDefinition -> 'fragment' FragmentName 'on' TypeCondition Directives SelectionSet : {extract_atom('$1'), '$2', extract_atom('$3'), '$4', '$5', '$6'}.

TypeCondition -> NamedType : '$1'.

VariableDefinitions -> '(' VariableDefinitionList ')' : {'$2'}.
VariableDefinitionList -> VariableDefinition : ['$1'].
VariableDefinitionList -> VariableDefinition VariableDefinitionList : ['$1'|'$2'].
VariableDefinition -> Variable ':' Type : {'$1', '$3'}.
VariableDefinition -> Variable ':' Type DefaultValue : {'$1', '$3', '$4'}.
Variable -> '$' Name : {extract_atom('$1'), '$2'}.

DefaultValue -> '=' Value : '$2'.

Type -> NamedType : '$1'.
Type -> ListType : '$1'.
Type -> NonNullType : '$1'.
NamedType -> Name : '$1'.
ListType -> '[' Type ']' : ['$2'].
NonNullType -> NamedType '!' : {'$1', extract_atom('$2')}.
NonNullType -> ListType '!' : {'$1', extract_atom('$2')}.

Selections -> Selection : ['$1'].
Selections -> Selection Selections : ['$1'|'$2'].

Selection -> Field : '$1'.
Selection -> FragmentSpread : '$1'.
Selection -> InlineFragment : '$1'.

FragmentSpread -> '...' FragmentName : '$2'.
FragmentSpread -> '...' FragmentName Directives : {extract_atom('$1'), '$2', '$3'}.

InlineFragment -> '...' 'on' TypeCondition SelectionSet : {extract_atom('$1'), extract_atom('$2'), '$3', '$4'}.
InlineFragment -> '...' 'on' TypeCondition Directives SelectionSet : {extract_atom('$1'), extract_atom('$2'), '$3', '$4', '5'}.

FragmentName -> Name : '$1'.

Field -> Name : '$1'.
Field -> Name SelectionSet : {'$1', '$2'}.
Field -> Name Arguments : {'$1', '$2'}.
Field -> Name Arguments SelectionSet : {'$1', '$2', '$3'}.
Field -> Alias Name : {'$1', '$2'}.
Field -> Alias Name Arguments : {'$1', '$2', '$3'}.
Field -> Alias Name SelectionSet : {'$1', '$2', '$3'}.
Field -> Alias Name Arguments SelectionSet : {'$1', '$2', '$3', '$4'}.
Field -> Alias Name Directives : {'$1', '$2', '$3'}.
Field -> Alias Name Arguments Directives : {'$1', '$2', '$3', '$4'}.
Field -> Alias Name Directives SelectionSet : {'$1', '$2', '$3', '$4'}.
Field -> Alias Name Arguments Directives SelectionSet : {'$1', '$2', '$3', '$4', '$5'}.

Alias -> Name ':' : '$1'.

Arguments -> '(' ArgumentList ')' : '$2'.
ArgumentList -> Argument : ['$1'].
ArgumentList -> Argument ArgumentList : ['$1'|'$2'].
Argument -> Name ':' Value : {'$1', '$3'}.

Directives -> Directive : ['$1'].
Directives -> Directive Directives : ['$1'|'$2'].
Directive -> '@' Name : {extract_atom('$1'), '$2'}.
Directive -> '@' Name Arguments : {extract_atom('$1'), '$2', '$3'}.

Name -> name : extract_token('$1').

Value -> Variable : '$1'.
Value -> int_value : extract_integer('$1').
Value -> float_value : extract_float('$1').
Value -> string_value : extract_token('$1').
Value -> boolean_value : extract_boolean('$1').
Value -> EnumValue : '$1'.
Value -> ListValue : '$1'.

EnumValue -> Name : '$1'.
ListValue -> '[' ']' : [].
ListValue -> '[' Values ']' : '$2'.
Values -> Value : ['$1'].
Values -> Value Values : ['$1'|'$2'].

Erlang code.

extract_atom({Value, _Line}) -> Value.

extract_token({_Token, _Line, Value}) -> Value.

extract_integer({_Token, _Line, Value}) ->
  {Int, []} = string:to_integer(Value), Int.

extract_float({_Token, _Line, Value}) ->
  {Float, []} = string:to_float(Value), Float.

extract_boolean({_Token, _Line, "true"}) -> true;
extract_boolean({_Token, _Line, "false"}) -> false.
