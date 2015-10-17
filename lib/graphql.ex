defmodule GraphQL do
  @moduledoc ~S"""
  The main GraphQL module.

  The `GraphQL` module provides a
  [GraphQL](http://facebook.github.io/graphql/) implementation for Elixir.

  ## Parse a query

  Parse a GraphQL query

      iex> GraphQL.parse "{ hello }"
      %{definitions: [
        %{kind: :OperationDefinition, loc: %{start: 0},
          operation: :query,
          selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
            selections: [
              %{kind: :Field, loc: %{start: 0}, name: "hello"}
            ]
          }}
        ],
        kind: :Document, loc: %{start: 0}
      }

  ## Execute a query

  Execute a GraphQL query against a given schema / datastore.

      # iex> GraphQL.execute schema, "{ hello }"
      # [data: [hello: world]]
  """

  alias GraphQL.Schema
  alias GraphQL.SyntaxError

  defmodule ObjectType do
    defstruct name: "RootQueryType", description: "", fields: []
  end

  defmodule FieldDefinition do
    defstruct name: nil, type: "String", resolve: nil
  end

  @doc """
  Tokenize the input string into a stream of tokens.

      iex> GraphQL.tokenize("{ hello }")
      [{ :"{", 1 }, { :name, 1, 'hello' }, { :"}", 1 }]

  """
  def tokenize(input_string) when is_binary(input_string) do
    input_string |> to_char_list |> tokenize
  end

  def tokenize(input_string) do
    {:ok, tokens, _} = :graphql_lexer.string input_string
    tokens
  end

  @doc """
  Parse the input string into a Document AST.

      iex> GraphQL.parse("{ hello }")
      %{definitions: [
        %{kind: :OperationDefinition, loc: %{start: 0},
          operation: :query,
          selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
            selections: [
              %{kind: :Field, loc: %{start: 0}, name: "hello"}
            ]
          }}
        ],
        kind: :Document, loc: %{start: 0}
      }
  """
  def parse(input_string) when is_binary(input_string) do
    input_string |> to_char_list |> parse
  end

  def parse(input_string) do
    case input_string |> tokenize |> :graphql_parser.parse do
      {:ok, parse_result} ->
        parse_result
      {:error, {line_number, _, errors}} ->
        raise SyntaxError, line: line_number, errors: errors
    end
  end

  @doc """
  Execute a query against a schema.

      # iex> GraphQL.execute(schema, "{ hello }")
      # [data: [hello: world]]
  """
  def execute(schema, query) do
    document = parse(query)
    query_fields = hd(document[:definitions])[:selectionSet][:selections]
    query_field_names = for field <- query_fields, do: to_string(field[:name])

    %Schema{
      query: _query_root = %ObjectType{
        name: "RootQueryType",
        fields: fields
      }
    } = schema

    result = for field <- fields,
      qf <- query_field_names,
      qf == field.name,
      do: {String.to_atom(field.name), field.resolve.()}
    [data: result]
  end
end
