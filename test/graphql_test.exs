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
    {:ok, result} = execute(schema, "{ a }", root_value: %{a: "A"})
    assert_data(result, %{a: "A"})
  end

  test "Report parse error with message" do
    {_, result} = execute(schema, "{")
    assert_has_error(result, %{message: "GraphQL: syntax error before:  on line 1", line_number: 1})

    {_, result} = execute(schema, "a")
    assert_has_error(result, %{message: "GraphQL: syntax error before: \"a\" on line 1", line_number: 1})
  end
end
