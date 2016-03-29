
defmodule GraphQL.Validation.Rules do

  alias GraphQL.Validation.Rules.{
    FieldsOnCorrectType,
    UniqueOperationNames
  }

  # All of the known validation rules.
  # TODO: it would be great if the rules auto-registered themselves.
  # A task for a rainy day.
  @rules [
    %UniqueOperationNames{},
    %FieldsOnCorrectType{}
  ]

  def all(), do: @rules
end
