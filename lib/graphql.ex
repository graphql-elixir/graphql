defmodule GraphQL do
  @moduledoc ~S"""
  The main GraphQL module.

  The `GraphQL` module provides a
  [GraphQL](http://facebook.github.io/graphql/) implementation for Elixir.

  ## Execute a query

  Execute a GraphQL query against a given schema / datastore.

      # iex> GraphQL.execute schema, "{ hello }"
      # {:ok, %{hello: "world"}}
  """

  alias GraphQL.Validation.Validator
  alias GraphQL.Execution.Executor

  @doc """
  Execute a query against a schema (with validation)

      # iex> GraphQL.execute(schema, "{ hello }")
      # {:ok, %{hello: world}}
  """
  def execute(schema, query, root_value \\ %{}, variable_values \\ %{}, operation_name \\ nil) do
    execute_with_optional_validation(true, schema, query, root_value, variable_values, operation_name)
  end

  @doc """
  Execute a query against a schema (without validation)

      # iex> GraphQL.execute(schema, "{ hello }")
      # {:ok, %{hello: world}}
  """
  def execute_without_validation(schema, query, root_value \\ %{}, variable_values \\ %{}, operation_name \\ nil) do
    execute_with_optional_validation(false, schema, query, root_value, variable_values, operation_name)
  end

  defp execute_with_optional_validation(should_validate, schema, query, root_value, variable_values, operation_name) do
    # NOTE: it would be nice if we could compose functions together in a chain (with ot without validation step).
    # See: http://www.zohaib.me/railway-programming-pattern-in-elixir/
    case GraphQL.Lang.Parser.parse(query) do
      {:ok, document} ->
        case optionally_validate(should_validate, schema, document) do
          :ok ->
            case Executor.execute(schema, document, root_value, variable_values, operation_name) do
              {:ok, response} -> {:ok, %{data: response}}
              {:error, errors} -> {:error, errors}
            end
          {:error, errors} ->
            {:error, errors}
        end
      {:error, errors} ->
        {:error, errors}
    end
  end

  defp optionally_validate(false, _schema, _document), do: :ok
  defp optionally_validate(true, schema, document), do: Validator.validate(schema, document)
end
