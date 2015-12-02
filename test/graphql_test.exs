defmodule GraphQLTest do
  use ExUnit.Case, async: true
  doctest GraphQL

  test "Execute simple query" do
    schema = %GraphQL.Schema{query: %GraphQL.ObjectType{fields: %{a: %{type: "String"}}}}
    assert GraphQL.execute(schema, "{ a }", %{"a" => "A"}) == {:ok, %{"a" => "A"}}
  end

  test "Report parse error with message" do
    schema = %GraphQL.Schema{query: %GraphQL.ObjectType{fields: %{a: %{type: "String"}}}}
    assert GraphQL.execute(schema, "{") ==
      {:error, %{errors: [%{message: "GraphQL: syntax error before:  on line 1", line_number: 1}]}}
    assert GraphQL.execute(schema, "a") ==
      {:error, %{errors: [%{message: "GraphQL: syntax error before: \"a\" on line 1", line_number: 1}]}}
  end
end
