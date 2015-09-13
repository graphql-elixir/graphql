defmodule GraphqlTest do
  use ExUnit.Case, async: true

  def assert_parse(input_string, expected_output) do
    assert Graphql.parse(input_string) == expected_output
  end

  test "parse char list" do
    assert_parse '{ hero }',
      [kind: :Document, loc: [start: 0],
        definitions: [[kind: :OperationDefinition, loc: [start: 0], operation: :query,
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
           selections: [[kind: :Field, loc: [start: 0], name: 'hero']]]]]]
  end

  test "parse string" do
    assert_parse "{ hero }",
      [kind: :Document, loc: [start: 0],
        definitions: [[kind: :OperationDefinition, loc: [start: 0], operation: :query,
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
           selections: [[kind: :Field, loc: [start: 0], name: 'hero']]]]]]
  end
end
