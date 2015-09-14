defmodule GraphQL do

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
end

defmodule GraphQL.SyntaxError do
  defexception line: nil, errors: "Syntax error"

  def message(exception) do
    "#{exception.errors} on line #{exception.line}"
  end
end
