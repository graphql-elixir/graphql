defmodule GraphQLTest do
  use ExUnit.Case, async: true
  doctest GraphQL

  import ExUnit.TestHelpers

  test "parse char list" do
    assert_parse "{ hero }",
      [kind: :Document, loc: [start: 0],
        definitions: [[kind: :OperationDefinition, loc: [start: 0], operation: :query,
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
           selections: [[kind: :Field, loc: [start: 0], name: "hero"]]]]]]
  end

  test "parse string" do
    assert_parse "{ hero }",
      [kind: :Document, loc: [start: 0],
        definitions: [[kind: :OperationDefinition, loc: [start: 0], operation: :query,
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
           selections: [[kind: :Field, loc: [start: 0], name: "hero"]]]]]]
  end

  test "ReportError with message" do
    assert_raise GraphQL.SyntaxError, "syntax error before: \"a\" on line 1", fn -> GraphQL.parse("a") end
    assert_raise GraphQL.SyntaxError, "syntax error before: '}' on line 1", fn -> GraphQL.parse("{}") end
    assert_raise GraphQL.SyntaxError, "syntax error before:  on line 1", fn -> GraphQL.parse("{ a") end
    assert_raise GraphQL.SyntaxError, "syntax error before: \"a\" on line 1", fn -> GraphQL.parse("a }") end
  end
end
