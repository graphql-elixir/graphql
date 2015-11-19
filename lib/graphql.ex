defmodule GraphQL do
  @moduledoc ~S"""
  The main GraphQL module.

  The `GraphQL` module provides a
  [GraphQL](http://facebook.github.io/graphql/) implementation for Elixir.

  ## Parse a query

  Parse a GraphQL query

      iex> GraphQL.parse "{ hello }"
      {:ok, %{definitions: [
        %{kind: :OperationDefinition, loc: %{start: 0},
          operation: :query,
          selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
            selections: [
              %{kind: :Field, loc: %{start: 0}, name: "hello"}
            ]
          }}
        ],
        kind: :Document, loc: %{start: 0}
      }}

  ## Execute a query

  Execute a GraphQL query against a given schema / datastore.

      # iex> GraphQL.execute schema, "{ hello }"
      # {:ok, %{hello: "world"}}
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
      {:ok,
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
      }
  """
  def parse(input_string) when is_binary(input_string) do
    input_string |> to_char_list |> parse
  end

  def parse(input_string) do
    case input_string |> tokenize |> :graphql_parser.parse do
      {:ok, parse_result} ->
        {:ok, parse_result}
      {:error, {line_number, _, errors}} ->
        {:error, %{errors: [%{message: "GraphQL: #{errors} on line #{line_number}", line_number: line_number}]}}
    end
  end

  @doc """
  Execute a query against a schema.

      # iex> GraphQL.execute(schema, "{ hello }")
      # {:ok, %{hello: world}}
  """
  def execute(schema, query) do
    case parse(query) do
      {:ok, document} ->
        query_fields = hd(document[:definitions])[:selectionSet][:selections]

        %Schema{
          query: _query_root = %ObjectType{
            name: "RootQueryType",
            fields: fields
          }
        } = schema

        result = for fd <- fields, qf <- query_fields, qf[:name] == fd.name do
          arguments = Map.get(qf, :arguments, [])
                      |> Enum.map(&parse_argument/1)

          {String.to_atom(fd.name), fd.resolve.(arguments)}
        end

        {:ok, Enum.into(result, %{})}
      {:error, error} -> {:error, error}
    end
  end

  defp parse_argument(%{kind: :Argument, loc: _, name: name, value: %{kind: _, loc: _, value: value}}) do
    {String.to_atom(name), value}
  end
end
