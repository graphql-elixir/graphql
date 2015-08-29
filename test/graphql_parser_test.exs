defmodule GraphqlParserTest do
  use ExUnit.Case

  def assert_parse(input, output) do
    {:ok, tokens, _} = :graphql_lexer.string(input)
    # IO.inspect tokens
    {:ok, parse_result} = :graphql_parser.parse(tokens)
    assert parse_result == output
  end

  def assert_parse_tokens(input_tokens, output) do
    {:ok, parse_result} = :graphql_parser.parse(input_tokens)
    assert parse_result == output
  end

  # just tokens
  test "simple selection set" do
    assert_parse_tokens [
      {:'{', 1},
      {:name, 1, 'hero'},
      {:'}', 1}
    ], [{ ['hero'] }]
  end

  test "multiple selection set" do
    assert_parse_tokens [
      {:'{', 1},
      {:name, 1, 'id'},
      {:name, 1, 'name'},
      {:'}', 1}
    ], [{ ['id', 'name'] }]
  end

  # strings
  test "simple selection set strings" do
    assert_parse '{ hero }', [{ ['hero'] }]
  end

  test "multiple selection set strings" do
    assert_parse '{ id firstName lastName }', [{ ['id', 'firstName', 'lastName'] }]
  end

  # test "multiple selection set strings" do
  #   assert_parse '{ id firstName lastName }', { 'id', 'firstName', 'lastName' }
  # end
  #
  #
  # assert_parse '{ me { name } }', {  }

end
