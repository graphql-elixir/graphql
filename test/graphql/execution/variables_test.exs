defmodule GraphQL.Execution.Executor.VariableTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  alias GraphQL.Schema
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.List
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.String
  alias GraphQL.Type.Input

  defmodule GraphQL.Type.TestComplexScalar do
    defstruct name: "ComplexScalar", description: ""
  end
  # TODO: Why can't I have a defimpl in here?
  # Should I put this in a support file?
  alias GraphQL.Type.TestComplexScalar

  def test_input_object do
    %Input{
      name: "TestInputObject",
      fields: %{
        a: %{ type: %String{} },
        b: %{ type: %List{ofType: %String{} } },
        c: %{ type: %NonNull{ofType: %String{} } },
        d: %{ type: %TestComplexScalar{} }
      }
    }
  end

  def test_nested_input_object do
    %Input{
      name: "TestNestedInputObject",
      fields: %{
        na: %{ type: %NonNull{ofType: test_input_object } },
        nb: %{ type: %NonNull{ofType: %String{} } }
      }
    }
  end

  def test_type do
    %ObjectType{
      name: "TestType",
      fields: %{
        field_with_object_input: %{
          type: %String{},
          args: %{
            input: %{ type: test_input_object }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        },
        field_with_nullable_string_input: %{
          type: %String{},
          args: %{
            input: %{ type: %String{} }
          },
          resolve: fn
            (_, %{input: input}, _) -> input
            (_, _, _) -> nil
          end
        },
        field_with_nonnullable_string_input: %{
          type: %String{},
          args: %{
            input: %{ type: %NonNull{ofType: %String{} } }
          },
          resolve: fn
            (_, %{input: input}, _) -> input
            (_, _, _) -> nil
          end
        },
        field_with_default_parameter: %{
          type: %String{},
          args: %{
            input: %{ type: %String{}, defaultValue: "Hello World" }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        },
        field_with_nested_input: %{
          type: %String{},
          args: %{
            input: %{ type: test_nested_input_object, defaultValue: "Hello World" }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        },
        list: %{
          type: %String{},
          args: %{
            input: %{ type: %List{ofType: %String{} } }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        },
        nnList: %{
          type: %String{},
          args: %{
            input: %{ type: %NonNull{ofType: %List{ofType: %String{} } } }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        },
        listNN: %{
          type: %String{},
          args: %{
            input: %{ type: %List{ofType: %NonNull{ofType: %String{} } } }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        },
        nnListNN: %{
          type: %String{},
          args: %{
            input: %{ type: %NonNull{ofType: %List{ofType: %NonNull{ofType: %String{} } } } }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        }
      } # /fields
    }
  end

  def schema do
    %Schema{ query: test_type }
  end

  test "Handles objects and nullability using inline structs executes with complex input" do
    query = """
    {
      field_with_object_input(input: {a: "foo", b: ["bar"], c: "baz"})
    }
    """

    assert_execute {query, schema},
      # the inner value should be a string as part of String.coerce.
      # for now just get the right data..
      %{"field_with_object_input" => %{"a": "foo", "b": ["bar"], "c": "baz"}}
  end

  test "Handles objects and nullability using inline structs properly parses single value to list" do
    query = """
    {
      field_with_object_input(input: {a: "foo", b: "bar", c: "baz"})
    }
    """
    assert_execute {query, schema},
      %{"field_with_object_input" => %{"a": "foo", "b": ["bar"], "c": "baz"}}
  end

  test "Handles objects and nullability using inline structs does not use incorrect value" do
    query = """
    {
      field_with_object_input(input: ["foo", "bar", "baz"])
    }
    """
    assert_execute {query, schema},
      %{"field_with_object_input" => nil}
  end

  def using_variables_query do  """
    query q($input: TestInputObject) {
      field_with_object_input(input: $input)
    }
  """ end
  test "Handles objects and nullability using variables executes with complex input" do
    params = %{ "input" => %{ a: 'foo', b: [ 'bar' ], c: 'baz' } }
    assert_execute {using_variables_query, schema, nil, params},
      %{"field_with_object_input" => %{"a" => 'foo', "b" => ['bar'], "c" => 'baz'}}
  end

  test "Handles objects and nullability using variables uses default value when not provided" do
    query = """
      query q($input: TestInputObject = {a: "foo", b: ["bar"], c: "baz"}) {
        field_with_object_input(input: $input)
      }
    """
    assert_execute {query, schema},
      %{"field_with_object_input" => %{"a" => "foo", "b" => ["bar"], "c" => "baz"}}
  end

  test "Handles objects and nullability using variables properly parses single value to list" do
    query = """
      query q($input: TestInputObject = {a: "foo", b: "bar", c: "baz"}) {
        field_with_object_input(input: $input)
      }
    """
    assert_execute {query, schema},
      %{"field_with_object_input" => %{"a" => "foo", "b" => ["bar"], "c" => "baz"}}
  end

  test "Handles objects and nullability using variables executes with complex scalar input" do
    params = %{ "input" => %{ c: 'foo', d: 'SerializedValue' } };

    assert_execute {using_variables_query, schema, nil, params},
      %{"field_with_object_input" => %{"c" => 'foo', "d" => 'SerializedValue'}}
  end

  @tag :skip
  test "Handles objects and nullability using variables errors on null for nested non-null" do
    params = %{ "input" => %{ a: 'foo', b: 'bar', c: nil } }

    assert_execute {using_variables_query, schema, nil, params}, "should have errored"
  end

  @tag :skip
  test "Handles objects and nullability using variables errors on incorrect type" do
    params = %{ "input" => "foo bar" }
    assert_execute {using_variables_query, schema, nil, params}, "should have errored"
  end

  @tag :skip
  test "Handles objects and nullability using variables errors on omission of nested non-null" do
    params = %{ "input" => %{ a: 'foo', b: 'bar' } }
    assert_execute {using_variables_query, schema, nil, params}, "should have errored"
  end

  @tag :skip
  test "Handles objects and nullability using variables errors on deep nested errors and with many errors" do
    params = %{ "input" => %{ na: %{ a: 'foo' } } }
    query = """
      query q($input: TestNestedInputObject) {
        fieldWithNestedObjectInput(input: $input)
      }
    """
    assert_execute {query, schema, nil, params}, "should have errored"
  end

  # Handles nullable scalars
  test "Handles nullable scalars allows nullable inputs to be omitted" do
    query = "{ field_with_nullable_string_input }"
    assert_execute {query, schema},
      %{"field_with_nullable_string_input" => nil}
  end

  test "Handles nullable scalars allows nullable inputs to be omitted in a variable" do
    query = """
      query set_nullable($value: String) {
        field_with_nullable_string_input(input: $value)
      }
    """
    assert_execute {query, schema},
      %{"field_with_nullable_string_input" => nil}
  end

  test "Handles nullable scalars allows nullable inputs to be omitted in an unlisted variable" do
    query = """
      query set_nullable {
        field_with_nullable_string_input(input: $value)
      }
    """
    assert_execute {query, schema},
      %{"field_with_nullable_string_input" => nil}
  end

  test "Handles nullable scalars allows nullable inputs to be set to null in a variable" do
    query = """
      query set_nullable($value: String) {
        field_with_nullable_string_input(input: $value)
      }
    """
    assert_execute {query, schema, nil, %{"value" => nil}},
      %{"field_with_nullable_string_input" => nil}
  end

  test "Handles nullable scalars allows nullable inputs to be set to a value in a variable" do
    query = """
      query set_nullable($value: String) {
        field_with_nullable_string_input(input: $value)
      }
    """
    assert_execute {query, schema, nil, %{"value" => "a"}},
      %{"field_with_nullable_string_input" => "a"}
  end

  test "Handles nullable scalars allows non-nullable inputs to be set to a value directly" do
    query = ~s[ { field_with_nullable_string_input(input: "a") } ]
    assert_execute {query, schema},
      %{"field_with_nullable_string_input" => "a"}
  end

  # Handles non-nullable scalars
  @tag :skip
  test "Handles non-nullable scalars does not allow non-nullable inputs to be omitted in a variable" do
    query = """
      query sets_non_nullable($value: String!) {
        field_with_nonnullable_string_input(input: $value)
      }
    """
    assert_execute {query, schema}, "should have errored"
  end

  @tag :skip
  test "Handles non-nullable scalars does not allow non-nullable inputs to be set to null in a variable" do
    query = """
      query sets_non_nullable($value: String!) {
        field_with_nonnullable_string_input(input: $value)
      }
    """
    assert_execute {query, schema, nil, %{"value" => nil}}, "should have errored"
  end

  test "Handles non-nullable scalars allows non-nullable inputs to be set to a value in a variable" do
    query = """
      query sets_non_nullable($value: String!) {
        field_with_nonnullable_string_input(input: $value)
      }
    """
    assert_execute {query, schema, nil, %{"value" => "a"}},
      %{"field_with_nonnullable_string_input" => "a"}
  end

  test "Handles non-nullable scalars allows non-nullable inputs to be set to a value directly" do
    query = ~s[ { field_with_nonnullable_string_input(input: "a") } ]

    assert_execute {query, schema, nil},
      %{"field_with_nonnullable_string_input" => "a"}
  end

  test "Handles non-nullable scalars passes along null for non-nullable inputs if explcitly set in the query" do
    query = ~s[ { field_with_nonnullable_string_input } ]

    assert_execute {query, schema, nil},
      %{"field_with_nonnullable_string_input" => nil}
  end

  # Handles lists and nullability


end
