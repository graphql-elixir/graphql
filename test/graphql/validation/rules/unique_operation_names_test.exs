
Code.require_file "../../../support/validations.exs", __DIR__

defmodule GraphQL.Validation.Rules.UniqueOperationNamesTest do
  use ExUnit.Case, async: true

  import ValidationsSupport

  alias GraphQL.Validation.Rules.UniqueOperationNames

  test "no operations" do
    assert_passes_rule(""" 
      fragment fragA on Type {
        field
      }
    """, %UniqueOperationNames{})
  end

  test "one anon operation" do
    assert_passes_rule("""
      {
        field
      }
    """, %UniqueOperationNames{})
  end

  test "one named operation" do
    assert_passes_rule("""
      query Foo {
        field
      }
    """, %UniqueOperationNames{})
  end

  test "multiple operations" do
    assert_passes_rule("""
      query Foo {
        field
      }

      query Bar {
        field
      }
    """, %UniqueOperationNames{})
  end

  test "multiple operations of different types" do
    assert_passes_rule("""
      query Foo {
        field
      }

      mutation Bar {
        field
      }

      # TODO: add this when subscription support is added
      #subscription Baz {
      #  field
      #}
    """, %UniqueOperationNames{})
  end

  test "fragment and operation named the same" do
    assert_passes_rule("""
      query Foo {
        ...Foo
      }
      fragment Foo on Type {
        field
      }
    """, %UniqueOperationNames{})
  end

  test "multiple operations of same name" do
    assert_fails_rule("""
      query Foo {
        fieldA
      }
      query Foo {
        fieldB
      }
    """, %UniqueOperationNames{})
  end

  test "multiple ops of same name of different types (mutation)" do
    assert_fails_rule("""
      query Foo {
        fieldA
      }
      mutation Foo {
        fieldB
      }
    """, %UniqueOperationNames{})
  end

  @tag :skip
  test "multiple ops of same name of different types (subscription)" do
    assert_fails_rule("""
      query Foo {
        fieldA
      }
      subscription Foo {
        fieldB
      }
    """, %UniqueOperationNames{})
  end
end
