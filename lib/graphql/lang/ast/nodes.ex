
defmodule GraphQL.Lang.AST.Nodes do
  @kinds %{
    Name:                       [],
    Document:                   [:definitions],
    OperationDefinition:        [:name, :variableDefinitions, :directives, :selectionSet],
    VariableDefinition:         [:variable, :type, :defaultValue],
    Variable:                   [:name],
    SelectionSet:               [:selections],
    Field:                      [:alias, :name, :arguments, :directives, :selectionSet],
    Argument:                   [:name, :value],
    FragmentSpread:             [:name, :directives],
    InlineFragment:             [:typeCondition, :directives, :selectionSet],
    FragmentDefinition:         [:name, :typeCondition, :directives, :selectionSet],
    IntValue:                   [],
    FloatValue:                 [],
    StringValue:                [],
    BooleanValue:               [],
    EnumValue:                  [],
    ListValue:                  [:values],
    ObjectValue:                [:fields],
    ObjectField:                [:name, :value],
    Directive:                  [:name, :arguments],
    NamedType:                  [:name],
    ListType:                   [:type],
    NonNullType:                [:type],
    ObjectTypeDefinition:       [:name, :interfaces, :fields],
    FieldDefinition:            [:name, :arguments, :type],
    InputValueDefinition:       [:name, :type, :defaultValue],
    InterfaceTypeDefinition:    [:name, :fields],
    UnionTypeDefinition:        [:name, :types],
    ScalarTypeDefinition:       [:name],
    EnumTypeDefinition:         [:name, :values],
    EnumValueDefinition:        [:name],
    InputObjectTypeDefinition:  [:name, :fields],
    TypeExtensionDefinition:    [:definition]
  }

  def kinds, do: @kinds

  @type operation_node :: %{
    kind: :OperationDefinition,
    operation: atom
  }
end

