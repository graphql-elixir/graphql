defmodule GraphQL do
  @moduledoc ~S"""
  The main GraphQL module.

  The `GraphQL` module provides a
  [GraphQL](http://facebook.github.io/graphql/) implementation for Elixir.

  ## Parse a query

  Parse a GraphQL query

      GraphQL.parse "{ hello }"
      #=> [kind: :Document, loc: [start: 0],
      #  definitions: [[kind: :OperationDefinition, loc: [start: 0], operation: :query,
      #    selectionSet: [kind: :SelectionSet, loc: [start: 0],
      #     selections: [[kind: :Field, loc: [start: 0], name: "hello"]]]]]]

  ## Execute a query

  Execute a GraphQL query against a given schema / datastore.

      GraphQL.execute schema, "{ hello }"

  """

  defmodule Schema do
    defstruct query: nil, mutation: nil
  end

  defmodule ObjectType do
    defstruct name: "RootQueryType", description: "", fields: []
  end

  defmodule FieldDefinition do
    defstruct name: nil, type: "String", resolve: nil
  end

  @doc """
  Tokenize the input string into a stream of tokens.

  ## Examples

      GraphQL.tokenize("{ hello }")
      #=> [{ :"{", 1 }, { :name, 1, "hello" }, { :"}", 1 }]

  """
  def tokenize(input_string) do
    {:ok, tokens, _} = :graphql_lexer.string input_string
    tokens
  end

  @doc """
  Parse the input string into a Document AST.

  ## Examples

      GraphQL.parse("{ hello }")
      #=> [kind: :Document, loc: [start: 1],
      #  definitions: [[kind: :OperationDefinition, loc: [start: 1], operation: :query,
      #    selectionSet: [kind: :SelectionSet, loc: [start: 1],
      #     selections: [[kind: :Field, loc: [start: 1], name: "hello"]]]]]]

  """
  def parse(input_string) when is_binary(input_string) do
    input_string |> to_char_list |> parse
  end

  def parse(input_string) do
    case input_string |> tokenize |> :graphql_parser.parse do
      {:ok, parse_result} ->
        parse_result
      {:error, {line_number, _, errors}} ->
        raise GraphQL.SyntaxError, line: line_number, errors: errors
    end
  end

  @doc """
  Execute a query against a schema.

  ## Examples

      GraphQL.execute(schema, "{ hello }")
      #=> [data: [hello: world]]
  """
  def execute(schema, query) do
    document = parse(query)
    query_fields = hd(document[:definitions])[:selectionSet][:selections]

    %Schema{
      query: _query_root = %ObjectType{
        name: "RootQueryType",
        fields: fields
      }
    } = schema

    result = for fd <- fields, qf <- query_fields, qf[:name] == fd.name do
      arguments = Keyword.get(qf, :arguments, [])
                  |> Enum.map(&parse_argument/1)

      {String.to_atom(fd.name), fd.resolve.(arguments)}
    end

    [data: result]
  end

  defp parse_argument([kind: :Argument, loc: _, name: name, value: [kind: :StringValue, loc: _, value: value]]) do
    {String.to_atom(name), value}
  end
end

defmodule GraphQL.SyntaxError do
  defexception line: nil, errors: "Syntax error"

  def message(exception) do
    "#{exception.errors} on line #{exception.line}"
  end
end
