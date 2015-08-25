defmodule GraphqlParserTest do
  use ExUnit.Case

  def assert_tokens(input, tokens) do
    case :graphql_lexer.string(input) do
      {:ok, output, _} ->
        assert output == tokens
      {:error, {_, :graphql_lexer, output}, _} ->
        assert output == tokens
    end
  end

  test "Hello world" do
    input = '{ me }'
    {:ok, tokens, _} = :graphql_lexer.string(input)
    # {:ok, output, _} = :graphql_parser.parse(tokens)
    assert {} == :graphql_parser.parse(tokens)
  end


end
