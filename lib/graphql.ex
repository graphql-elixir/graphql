defmodule GraphQL do
  @moduledoc ~S"""
  An Elixir implementation of Facebook's GraphQL.

  This is the core GraphQL query parsing and execution engine whose goal is to be
  transport, server and datastore agnostic.

  In order to setup an HTTP server (ie Phoenix) to handle GraphQL queries you will
  need:

    * [GraphQL Plug](https://github.com/graphql-elixir/plug_graphql)

  Examples for Phoenix can be found:

    * [Phoenix Examples](https://github.com/graphql-elixir/hello_graphql_phoenix)

  Here you'll find some examples which can be used as a starting point for writing your own schemas.

  Other ways of handling queries will be added in due course.

  ## Execute a Query on the Schema

  First setup your schema

      iex> defmodule TestSchema do
      ...>   def schema do
      ...>     %GraphQL.Schema{
      ...>       query: %GraphQL.Type.ObjectType{
      ...>         name: "RootQueryType",
      ...>         fields: %{
      ...>           greeting: %{
      ...>             type: %GraphQL.Type.String{},
      ...>             resolve: &TestSchema.greeting/3,
      ...>             description: "Greeting",
      ...>             args: %{
      ...>               name: %{type: %GraphQL.Type.String{}, description: "The name of who you'd like to greet."},
      ...>             }
      ...>           }
      ...>         }
      ...>       }
      ...>     }
      ...>   end
      ...>   def greeting(_, %{name: name}, _), do: "Hello, #{name}!"
      ...>   def greeting(_, _, _), do: "Hello, world!"
      ...> end
      ...>
      ...> GraphQL.execute(TestSchema.schema, "{ greeting }")
      {:ok, %{data: %{"greeting" => "Hello, world!"}}}
      ...>
      ...> GraphQL.execute(TestSchema.schema, ~S[{ greeting(name: "Josh") }])
      {:ok, %{data: %{"greeting" => "Hello, Josh!"}}}
  """

  alias GraphQL.Validation.Validator
  alias GraphQL.Execution.Executor

  @doc """
  Execute a query against a schema (with validation)

      # iex> GraphQL.execute_with_opts(schema, "{ hello }")
      # {:ok, %{hello: world}}

  This is the preferred function signature for `execute` and
  will replace `execute/5`.
  """
  def execute_with_opts(schema, query, opts \\ []) do
    execute_with_optional_validation(schema, query, opts)
  end

  @doc """
  Execute a query against a schema (with validation)

      # iex> GraphQL.execute(schema, "{ hello }")
      # {:ok, %{hello: world}}

  *Deprecation warning*: This will be replaced in a future version with the
  function signature for `execute_with_opts/3`.
  """
  def execute(schema, query, root_value \\ %{}, variable_values \\ %{}, operation_name \\ nil) do
    execute_with_optional_validation(
      schema,
      query,
      root_value: root_value,
      variable_values: variable_values,
      operation_name: operation_name,
      validate: true
    )
  end

  @doc """
  Execute a query against a schema (without validation)

      # iex> GraphQL.execute(schema, "{ hello }")
      # {:ok, %{hello: world}}
  """
  def execute_without_validation(schema, query, opts) do
    execute_with_optional_validation(schema, query, Keyword.put(opts, :validate, false))
  end

  defp execute_with_optional_validation(schema, query, opts) do
    # TODO: use the `with` statement to compose write this in a nicer way
    case GraphQL.Lang.Parser.parse(query) do
      {:ok, document} ->
        case optionally_validate(Keyword.get(opts, :validate, true), schema, document) do
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
