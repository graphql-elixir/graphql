defmodule GraphQL.Validation.Rules.OperationsHaveUniqueNames do

  @moduledoc ~S"""
  Validates that operations have unique names.

  Specified here:
  https://github.com/facebook/graphql/blob/master/spec/Section%205%20--%20Validation.md#operation-name-uniqueness 
  """

  def validate(errors, validation_context) do
    names = operation_definition_names(validation_context[:document_ast])

    if Enum.count(Enum.uniq(names)) == Enum.count(names) do
      errors 
    else
      [ %{message: "operation names must be unique"} | errors ]
    end
  end

  defp operation_definition_names(document_ast) do
    for definition <- document_ast[:definitions],
      definition[:kind] == :OperationDefinition,
      do: definition[:name][:value]
  end
end


