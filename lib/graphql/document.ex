alias GraphQL.Location
alias GraphQL.Document
alias GraphQL.OperationDefinition
alias GraphQL.SelectionSet
alias GraphQL.Field

defmodule GraphQL.Location do
  @derive [Poison.Encoder]
  # type Location = {
  #   start: number;
  #   end: number;
  #   source?: ?Source
  # }
  defstruct start: 0, end: 0
  @type t :: %Location{start: non_neg_integer, end: non_neg_integer}
end

defmodule GraphQL.Document do
  @derive [Poison.Encoder]
  # type Document = {
  #   kind: 'Document';
  #   loc?: ?Location;
  #   definitions: Array<Definition>;
  # }
  defstruct kind: "Document", loc: nil, definitions: []
  @type t :: %Document{kind: String.t, loc: Location.t, definitions: List.t}
end

# type Definition = OperationDefinition
#                 | FragmentDefinition
#                 | TypeDefinition
#

defmodule GraphQL.SelectionSet do
  @derive [Poison.Encoder]
  # type SelectionSet = {
  #   kind: 'SelectionSet';
  #   loc?: ?Location;
  #   selections: Array<Selection>;
  # }
  defstruct kind: "SelectionSet", loc: nil, selections: []
end

defmodule GraphQL.OperationDefinition do
  @derive [Poison.Encoder]
  # type OperationDefinition = {
  #   kind: 'OperationDefinition';
  #   loc?: ?Location;
  #   // Note: subscription is an experimental non-spec addition.
  #   operation: 'query' | 'mutation' | 'subscription';
  #   name?: ?Name;
  #   variableDefinitions?: ?Array<VariableDefinition>;
  #   directives?: ?Array<Directive>;
  #   selectionSet: SelectionSet;
  # }
  defstruct kind: "OperationDefinition", loc: nil,
    operation: 'query',
    name: nil,
    variable_definitions: [],
    directives: [],
    selection_set: %SelectionSet{}
end

# type VariableDefinition = {
#   kind: 'VariableDefinition';
#   loc?: ?Location;
#   variable: Variable;
#   type: Type;
#   defaultValue?: ?Value;
# }
#
# type Variable = {
#   kind: 'Variable';
#   loc?: ?Location;
#   name: Name;
# }

# type Selection = Field
#                | FragmentSpread
#                | InlineFragment

defmodule GraphQL.Field do
  @derive [Poison.Encoder]
  # type Field = {
  #   kind: 'Field';
  #   loc?: ?Location;
  #   alias?: ?Name;
  #   name: Name;
  #   arguments?: ?Array<Argument>;
  #   directives?: ?Array<Directive>;
  #   selectionSet?: ?SelectionSet;
  # }
  defstruct kind: "Field", loc: nil,
    alias: nil, name: nil, arguments: [], directives: [], selection_set: nil
end
