
defmodule GraphQL.Validation.Rules do

  # All of the known validation rules.
  # TODO: it would be great if the rules auto-registered themselves.
  # A task for a rainy day.
  @rules [
    %GraphQL.Validation.Rules.UniqueOperationNames{},
    %GraphQL.Validation.Rules.FieldsOnCorrectType{},
    %GraphQL.Validation.Rules.ProvidedNonNullArguments{}
  ]

  def all(), do: @rules
end
