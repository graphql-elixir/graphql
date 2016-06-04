defmodule GraphQL.Execution.Executor.DirectiveTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  alias GraphQL.Schema
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.String

  defmodule TestSchema do
    def schema do
      Schema.new(%{
        query: %ObjectType{
          name: "TestType",
          fields: %{
            a: %{type: %String{}, resolve: "a"},
            b: %{type: %String{}, resolve: "b"}
          }
        }
      })
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

  test "if false omits the scalar" do
    {:ok, result} = execute(TestSchema.schema, "{ a, b @include(if: false) }")
    assert_data(result, %{a: "a"})
  end

  test "unless false includes scalar" do
    {:ok, result} = execute(TestSchema.schema, "{ a, b @skip(if: false) }")
    assert_data(result, %{a: "a", b: "b"})
  end

  test "unless true omits scalar" do
    {:ok, result} = execute(TestSchema.schema, "{ a, b @skip(if: true) }")
    assert_data(result, %{a: "a"})
  end

  test "if false omits fragment spread" do
    {:ok, result} = execute(TestSchema.schema, """
      query Q {
        a
        ...Frag @include(if: false)
      }
      fragment Frag on TestType {
        b
      }
      """)
    assert_data(result, %{a: "a"})
  end

  test "if true includes fragment spread" do
    {:ok, result} = execute(TestSchema.schema, """
      query Q {
        a
        ...Frag @include(if: true)
      }
      fragment Frag on TestType {
        b
      }
      """)
    assert_data(result, %{a: "a", b: "b"})
  end

  test "unless false includes fragment spread" do
    {:ok, result} = execute(TestSchema.schema, """
      query Q {
        a
        ...Frag @skip(if: false)
      }
      fragment Frag on TestType {
        b
      }
      """)
    assert_data(result, %{a: "a", b: "b"})
  end

  test "unless true omits fragment spread" do
    {:ok, result} = execute(TestSchema.schema, """
      query Q {
        a
        ...Frag @skip(if: true)
      }
      fragment Frag on TestType {
        b
      }
      """)
    assert_data(result, %{a: "a"})
  end

  test "if false omits inline fragment" do
    {:ok, result} = execute(TestSchema.schema, """
      query Q {
        a
        ... on TestType @include(if: false) {
          b
        }
      }
      """)
    assert_data(result, %{a: "a"})
  end

  test "if true includes inline fragment" do
    {:ok, result} = execute(TestSchema.schema, """
      query Q {
        a
        ... on TestType @include(if: true) {
          b
        }
      }
      """)
    assert_data(result, %{a: "a", b: "b"})
  end

  test "unless false includes inline fragment" do
    {:ok, result} = execute(TestSchema.schema, """
      query Q {
        a
        ... on TestType @skip(if: false) {
          b
        }
      }
      """)
    assert_data(result, %{a: "a", b: "b"})
  end

  test "unless true includes inline fragment" do
    {:ok, result} = execute(TestSchema.schema, """
      query Q {
        a
        ... on TestType @skip(if: true) {
          b
        }
      }
      """)
    assert_data(result, %{a: "a"})
  end

  test "if false omits anonymous inline fragment" do
    {:ok, result} = execute(TestSchema.schema, """
      query Q {
        a
        ... @include(if: false) {
          b
        }
      }
      """)
    assert_data(result, %{a: "a"})
  end

  test "if true includes anonymous inline fragment" do
    {:ok, result} = execute(TestSchema.schema, """
      query Q {
        a
        ... @include(if: true) {
          b
        }
      }
      """)
    assert_data(result, %{a: "a", b: "b"})
  end

  test "unless false includes anonymous inline fragment" do
    {:ok, result} = execute(TestSchema.schema, """
      query Q {
        a
        ... @skip(if: false) {
          b
        }
      }
      """)
    assert_data(result, %{a: "a", b: "b"})
  end

  test "unless true includes anonymous inline fragment" do
    {:ok, result} = execute(TestSchema.schema, """
      query Q {
        a
        ... @skip(if: true) {
          b
        }
      }
      """)
    assert_data(result, %{a: "a"})
  end

  test "include and no skip" do
    {:ok, result} = execute(TestSchema.schema, "{ a, b @include(if: true) @skip(if: false)}")
    assert_data(result, %{a: "a", b: "b"})
  end

  test "include and skip" do
    {:ok, result} = execute(TestSchema.schema, "{ a, b @include(if: true) @skip(if: true)}")
    assert_data(result, %{a: "a"})
  end

  test "no include or skip" do
    {:ok, result} = execute(TestSchema.schema, "{ a, b @include(if: false) @skip(if: false)}")
    assert_data(result, %{a: "a"})
  end

  test "include with variable" do
    query = "query q($test: Boolean) { a, b @include(if: $test) }"
    {:ok, result} = execute(TestSchema.schema, query, variable_values: %{"test" => false})
    assert_data(result, %{a: "a"})
  end

  test "skip with variable" do
    query = "query q($test: Boolean) { a, b @skip(if: $test) }"
    {:ok, result} = execute(TestSchema.schema, query, variable_values: %{"test" => true})
    assert_data(result, %{a: "a"})
  end
end
