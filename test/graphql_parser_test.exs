defmodule GraphqlParserTest do
  use ExUnit.Case

  def tokenize(string) do
    {:ok, tokens, _} = :graphql_lexer.string(string)
    tokens
  end

  def assert_parse(input_string, expected_tokens) do
    {:ok, parse_result} = :graphql_parser.parse(tokenize(input_string))
    assert parse_result == expected_tokens
  end

  test "simple selection set" do
    assert_parse '{hero}', [{ ['hero'] }]
  end

  test "aliased selection set" do
    assert_parse '{alias: hero}', [{ [{'alias', 'hero'}] }]
  end

  test "multiple selection set" do
    assert_parse '{id name}', [{ ['id', 'name'] }]
  end

  test "nested selection set" do
    assert_parse '{me {name}}', [{ [{ 'me', {['name']} }] }]
  end

  test "named query with nested selection set" do
    assert_parse 'query myName {me {name}}', [{ :query, 'myName', { [{ 'me', {['name']} }] } }]
  end

  test "nested selection set with arguments" do
    assert_parse '{user(id: 4) {name(thing: 123)}}', [{[{'user', [{'id', '4'}], {[{'name', [{'thing', '123'}]}]}}]}]
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
