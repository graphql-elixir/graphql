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
      {:ok, document} -> execute_definition(hd(document[:definitions]), schema)
      {:error, error} -> {:error, error}
    end
  end

  defp execute_definition(%{operation: :query}=definition, schema) do
    {:ok, Enum.map(definition[:selectionSet][:selections], fn(selection) -> execute_field(selection, schema.query) end)
          |> Enum.filter(fn(item) -> item != nil end)
          |> Enum.into(%{})}
  end

  defp execute_field(%{kind: :Field, selectionSet: selection_set}=field, schema) do
    fields = Enum.map(selection_set[:selections], fn(selection) -> 
        schema_fragment = Enum.find(schema.fields, fn(fd) -> fd.name == field[:name] end)
        execute_field(selection, schema_fragment) 
      end)

    fields = Enum.filter(fields, fn(item) -> item != nil end)

    if Enum.count(fields) > 0 do
      {String.to_atom(field[:name]), Enum.into(fields, %{})}
    else
      nil
    end

  end

  defp execute_field(%{kind: :Field}=field, schema) do
    arguments = Map.get(field, :arguments, []) |> Enum.map(&parse_argument/1)
    schema_fragment = Enum.find(schema.fields, fn(fd) -> fd.name == field[:name] end)
    case resolve(schema_fragment, arguments) do
      {:ok, value} -> {String.to_atom(field[:name]), value}
      {:error, _} -> nil
    end
  end

  defp resolve(nil, _), do: {:error, nil}
  defp resolve(field, arguments) do
    {:ok, field.resolve.(arguments)}
  end
  
  defp parse_argument(%{kind: :Argument, loc: _, name: name, value: %{kind: _, loc: _, value: value}}) do
    {String.to_atom(name), value}
  end
end
