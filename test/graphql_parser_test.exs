defmodule GraphqlParserTest do
  use ExUnit.Case

  def assert_parse(input, output) do
    {:ok, tokens, _} = :graphql_lexer.string(input)
    # IO.inspect tokens
    {:ok, parse_result} = :graphql_parser.parse(tokens)
    assert parse_result == output
  end

  test "simple name token" do
    assert_parse 'name', 'name'
  end

end
