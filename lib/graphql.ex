defmodule Graphql do

  def tokenize(input_string) do
    {:ok, tokens, _} = :graphql_lexer.string input_string
    tokens
  end

  def parse(input_string) when is_binary(input_string) do
    input_string |> to_char_list |> parse
  end

  def parse(input_string) do
    {:ok, parse_result} = input_string
      |> tokenize
      |> :graphql_parser.parse
    parse_result
  end

end
