defmodule GraphQL do

  defmodule Schema do
    defstruct query: nil, mutation: nil
  end

  defmodule ObjectType do
    defstruct name: "RootQueryType", description: "", fields: []
  end

  defmodule FieldDefinition do
    defstruct name: nil, type: "String", resolve: nil
  end

  def tokenize(input_string) do
    {:ok, tokens, _} = :graphql_lexer.string input_string
    tokens
  end

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

  def execute(schema, query) do
    document = parse(query)
    query_fields = hd(document[:definitions])[:selectionSet][:selections]
    query_field_names = for field <- query_fields, do: to_string(field[:name])

    %Schema{
      query: query_root = %ObjectType{
        name: "RootQueryType",
        fields: fields
      }
    } = schema

    result = for fd <- fields,
      qf <- query_field_names,
      qf == fd.name,
      do: {String.to_atom(fd.name), fd.resolve.()}
    [data: result]
  end
end

defmodule GraphQL.SyntaxError do
  defexception line: nil, errors: "Syntax error"

  def message(exception) do
    "#{exception.errors} on line #{exception.line}"
  end
end
