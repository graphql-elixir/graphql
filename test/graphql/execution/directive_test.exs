defmodule GraphQL.Execution.Executor.DirectiveTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  alias GraphQL.Schema
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.String

  defmodule TestSchema do
    def schema do
      %Schema{
        query: %ObjectType{
          name: "Test",
          fields: %{
            a: %{type: %String{}, resolve: "a"},
            b: %{type: %String{}, resolve: "b"}
          }
        }
      }
    end
  end

  test "works without directives" do
    {:ok, result} = execute(TestSchema.schema, "{ a, b }")
    assert_data(result, %{a: "a", b: "b"})
  end

  test "if true includes the scalar" do
    {:ok, result} = execute(TestSchema.schema, "{ a, b @include(if: true) }")
    assert_data(result, %{a: "a", b: "b"})
  end

  test "if false omits the  scalar" do
    {:ok, result} = execute(TestSchema.schema, "{ a, b @include(if: false) }")
    assert_data(result, %{a: "a"})
  end
end
