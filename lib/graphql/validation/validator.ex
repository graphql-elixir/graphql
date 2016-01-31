defmodule GraphQL.Validation.Validator do
  @moduledoc ~S"""
  Validation rules for a GraphQL operation
  """
  alias GraphQL.Validation.Rules.OperationsHaveUniqueNames

  @doc """
  Validates a parsed query.

  Returns :ok if the query is valid.
  Returns {:error, [errors...]} if the query contains errors.
  """
  def validate(schema, document_ast, root_value \\ %{}, variable_values \\ %{}, operation_name \\ nil) do

    validation_context = %{
      schema: schema,
      document_ast: document_ast,
      root_value: root_value,
      variable_values: variable_values,
      operation_name: operation_name
    }

    errors = [] |> OperationsHaveUniqueNames.validate(validation_context)

    if Enum.count(errors) == 0 do
      :ok
    else
      {:error, errors}
    end
  end
end


