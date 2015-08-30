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

  test "aliased selection set" do
    assert_parse_tokens [
      {:'{', 1},
      {:name, 1, 'alias'},
      {:':', 1},
      {:name, 1, 'hero'},
      {:'}', 1}
    ], [{ [{'alias', 'hero'}] }]
  end

  test "multiple selection set" do
    assert_parse_tokens [
      {:'{', 1},
      {:name, 1, 'id'},
      {:name, 1, 'name'},
      {:'}', 1}
    ], [{ ['id', 'name'] }]
  end

  test "nested selection set" do
    assert_parse_tokens [
      {:'{', 1},
      {:name, 1, 'me'},
      {:'{', 1},
      {:name, 1, 'name'},
      {:'}', 1},
      {:'}', 1}
    ], [{ [{ 'me', {['name']} }] }]
  end

  test "named query with nested selection set" do
    assert_parse_tokens [
      {:'query', 1},
      {:name, 1, 'myName'},
      {:'{', 1},
      {:name, 1, 'me'},
      {:'{', 1},
      {:name, 1, 'name'},
      {:'}', 1},
      {:'}', 1}
    ], [{ :query, 'myName', { [{ 'me', {['name']} }] } }]
  end

  test "nested selection set with arguments" do
    assert_parse_tokens [
      {:'{', 1},
      {:name, 1, 'user'},
      {:'(', 1},
      {:name, 1, 'id'},
      {:':', 1},
      {:int_value, 1, '4'},
      {:')', 1},
      {:'{', 1},
      {:name, 1, 'name'},
      {:'(', 1},
      {:name, 1, 'thing'},
      {:':', 1},
      {:int_value, 1, 'abc'},
      {:')', 1},
      {:'}', 1},
      {:'}', 1}
    ], [{[{'user', [{'id', '4'}], {[{'name', [{'thing', 'abc'}]}]}}]}]
  end

  # strings
  test "simple selection set string" do
    assert_parse '{ hero }', [
      {[ 'hero' ]}
    ]
  end

  test "aliased selection set string" do
    assert_parse '{ alias: hero }', [
      {[ {'alias', 'hero'} ]}
    ]
  end

  test "multiple selection set string" do
    assert_parse '{ id firstName lastName }', [
      { ['id', 'firstName', 'lastName'] }
    ]
  end

  test "nested selection set string" do
    assert_parse '{ me { name } }', [
      { [{ 'me', {['name']} }] }
    ]
  end

  test "named query with nested selection set string" do
    assert_parse 'query myName { user { name } }', [
      { :query, 'myName', {[
        { 'user', {['name']} }
      ]}
    }]
  end

  test "nested selection set with arguments string" do
    assert_parse '{ user(id: 4) { name ( thing : "abc" ) } }', [{[
        {'user', [{'id', '4'}], {
          [{'name', [{'thing', '"abc"'}]}]}}]}
    ]
  end

  test "aliased nested selection set with arguments string" do
    assert_parse '{ alias: user(id: 4) { alias2 : name ( thing : "abc" ) } }', [{[
        {'alias', 'user', [{'id', '4'}], {
          [{'alias2', 'name', [{'thing', '"abc"'}]}]}}]}
    ]
  end

end
