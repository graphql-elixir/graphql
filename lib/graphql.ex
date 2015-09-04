defmodule Graphql do

  def tokenize(input_string) do
    {:ok, tokens, _} = :graphql_lexer.string input_string
    tokens
  end

  def parse(input_string) do
    {:ok, parse_result} = :graphql_parser.parse tokenize(input_string)
    parse_result
  end

end
