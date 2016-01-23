defmodule GraphQLTest do
  use ExUnit.Case, async: true
  doctest GraphQL

  import ExUnit.TestHelpers

  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.String

  def schema do
    %GraphQL.Schema{
      query: %ObjectType{
        fields: %{
          a: %{type: %String{}}
        }
      }
    }
  end

  test "Execute simple query" do
    assert_execute {"{ a }", schema, %{a: "A"}}, %{a: "A"}
  end

  test "Report parse error with message" do
    assert_execute_error {"{", schema},
      [%{message: "GraphQL: syntax error before:  on line 1", line_number: 1}]
    assert_execute_error {"a", schema},
      [%{message: "GraphQL: syntax error before: \"a\" on line 1", line_number: 1}]
  end
end
