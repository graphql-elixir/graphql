
defmodule GraphQL.Validation.Rules do

  # All of the known validation rules.
  @rules [
    %GraphQL.Validation.Rules.UniqueOperationNames{},
    %GraphQL.Validation.Rules.FieldsOnCorrectType{},
    %GraphQL.Validation.Rules.ProvidedNonNullArguments{},
    %GraphQL.Validation.Rules.NoFragmentCycles{}
  ]

  def all(), do: @rules
end
