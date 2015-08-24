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
    :graphql_parser.string(input)
    assert_parse ~S"""
      {
        me {
          name
        }
      }
    """, 
  end


end
