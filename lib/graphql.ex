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
  def execute(schema, query, opts) do
    execute_with_optional_validation(true, schema, query, opts)
  end

  @doc """
  Execute a query against a schema (without validation)

      # iex> GraphQL.execute(schema, "{ hello }")
      # {:ok, %{hello: world}}
  """
  def execute_without_validation(schema, query, opts) do
    execute_with_optional_validation(false, schema, query, opts)
  end

  defp execute_with_optional_validation(should_validate, schema, query, opts) do
    # TODO: use the `with` statement to compose write this in a nicer way
    case GraphQL.Lang.Parser.parse(query) do
      {:ok, document} ->
        case optionally_validate(should_validate, schema, document) do
          :ok ->
            case Executor.execute(schema, document, opts) do
              {:ok, data, []} -> {:ok, %{data: data}}
              {:ok, data, errors} -> {:ok, %{data: data, errors: errors}}
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
