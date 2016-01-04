defmodule GraphQL.Lang.Visitor.VisitorTest do
  use ExUnit.Case, async: true

  test "traverses the tree" do
    {:ok, doc} = GraphQL.Lang.Parser.parse("{ a, b { x }, c }")

    GraphQL.Lang.Visitor.visit(doc, %{
      enter: fn(%{item: item}) ->
        send self, {:enter, item.kind, Dict.get(item, :value)}
        nil
      end,
      leave: fn(%{item: item}) ->
        send self, {:leave, item.kind, Dict.get(item, :value)}
        nil
      end
    })

    assert_received {:enter, :Document, nil}
    assert_received {:enter, :OperationDefinition, nil}
    assert_received {:enter, :SelectionSet, nil}
    assert_received {:enter, :Field, nil}
    assert_received {:enter, :Name, "a"}
    assert_received {:leave, :Name, "a"}
    assert_received {:leave, :Field, nil}
    assert_received {:enter, :Field, nil}
    assert_received {:enter, :Name, "b"}
    assert_received {:leave, :Name, "b"}
    assert_received {:enter, :SelectionSet, nil}
    assert_received {:enter, :Field, nil}
    assert_received {:enter, :Name, "x"}
    assert_received {:leave, :Name, "x"}
    assert_received {:leave, :Field, nil}
    assert_received {:leave, :SelectionSet, nil}
    assert_received {:leave, :Field, nil}
    assert_received {:enter, :Field, nil}
    assert_received {:enter, :Name, "c"}
    assert_received {:leave, :Name, "c"}
    assert_received {:leave, :Field, nil}
    assert_received {:leave, :SelectionSet, nil}
    assert_received {:leave, :OperationDefinition, nil}
    assert_received {:leave, :Document, nil}
  end

  # test "editing on enter"
  # test "editing on leave"
  # test "skipping a sub-tree"
  # test "early exit while entering"
  # test "early exit while leaving"

  test "named functions visitor API" do
    {:ok, doc} = GraphQL.Lang.Parser.parse("{ a, b { x }, c }")

    GraphQL.Lang.Visitor.visit(doc, %{
      Name: fn(%{item: item}) ->
        send self, {:enter, item.kind, Dict.get(item, :value)}
        nil
      end,
      SelectionSet: %{
        enter: fn(%{item: item}) ->
          send self, {:enter, item.kind, Dict.get(item, :value)}
          nil
        end,
        leave: fn(%{item: item}) ->
          send self, {:leave, item.kind, Dict.get(item, :value)}
          nil
        end
      }
    })

    assert_received {:enter, :SelectionSet, nil}
    assert_received {:enter, :Name, "a"}
    assert_received {:enter, :Name, "b"}
    assert_received {:enter, :SelectionSet, nil}
    assert_received {:enter, :Name, "x"}
    assert_received {:leave, :SelectionSet, nil}
    assert_received {:enter, :Name, "c"}
    assert_received {:leave, :SelectionSet, nil}
  end

  test "kitchen sink" do
    {:ok, doc} = GraphQL.Lang.Parser.parse("""
      query queryName($foo: ComplexType, $site: Site = MOBILE) {
        whoever123is: item(id: [123, 456]) {
          id ,
          ... on User @defer {
            field2 {
              id ,
              alias: field1(first:10, after:$foo,) @include(if: $foo) {
                id,
                ...frag
              }
            }
          }
        }
      }

      mutation likeStory {
        like(story: 123) @defer {
          story {
            id
          }
        }
      }

      fragment frag on Friend {
        foo(size: $size, bar: $b, obj: {key: "value"})
      }

      {
        unnamed(truthy: true, falsey: false),
        query
      }
    """)

    GraphQL.Lang.Visitor.visit(doc, %{
      enter: fn(%{item: item, key: key, parent: parent}) ->
        send self, {:enter, item.kind, key, parent && Dict.get(parent, :kind)}
        nil
      end,
      leave: fn(%{item: item, key: key, parent: parent}) ->
        send self, {:leave, item.kind, key, parent && Dict.get(parent, :kind)}
        nil
      end
    })

    assert_received {:enter, :Document, nil, nil}
    assert_received {:enter, :OperationDefinition, 0, nil}
    assert_received {:enter, :Name, :name, :OperationDefinition}
    assert_received {:leave, :Name, :name, :OperationDefinition}
    assert_received {:enter, :VariableDefinition, 0, nil}
    assert_received {:enter, :Variable, :variable, :VariableDefinition}
    assert_received {:enter, :Name, :name, :Variable}
    assert_received {:leave, :Name, :name, :Variable}
    assert_received {:leave, :Variable, :variable, :VariableDefinition}
    assert_received {:enter, :NamedType, :type, :VariableDefinition}
    assert_received {:enter, :Name, :name, :NamedType}
    assert_received {:leave, :Name, :name, :NamedType}
    assert_received {:leave, :NamedType, :type, :VariableDefinition}
    assert_received {:leave, :VariableDefinition, 0, nil}
    assert_received {:enter, :VariableDefinition, 1, nil}
    assert_received {:enter, :Variable, :variable, :VariableDefinition}
    assert_received {:enter, :Name, :name, :Variable}
    assert_received {:leave, :Name, :name, :Variable}
    assert_received {:leave, :Variable, :variable, :VariableDefinition}
    assert_received {:enter, :NamedType, :type, :VariableDefinition}
    assert_received {:enter, :Name, :name, :NamedType}
    assert_received {:leave, :Name, :name, :NamedType}
    assert_received {:leave, :NamedType, :type, :VariableDefinition}
    assert_received {:enter, :EnumValue, :defaultValue, :VariableDefinition}
    assert_received {:leave, :EnumValue, :defaultValue, :VariableDefinition}
    assert_received {:leave, :VariableDefinition, 1, nil}
    assert_received {:enter, :SelectionSet, :selectionSet, :OperationDefinition}
    assert_received {:enter, :Field, 0, nil}
    assert_received {:enter, :Name, :alias, :Field}
    assert_received {:leave, :Name, :alias, :Field}
    assert_received {:enter, :Name, :name, :Field}
    assert_received {:leave, :Name, :name, :Field}
    assert_received {:enter, :Argument, 0, nil}
    assert_received {:enter, :Name, :name, :Argument}
    assert_received {:leave, :Name, :name, :Argument}
    assert_received {:enter, :ListValue, :value, :Argument}
    assert_received {:enter, :IntValue, 0, nil}
    assert_received {:leave, :IntValue, 0, nil}
    assert_received {:enter, :IntValue, 1, nil}
    assert_received {:leave, :IntValue, 1, nil}
    assert_received {:leave, :ListValue, :value, :Argument}
    assert_received {:leave, :Argument, 0, nil}
    assert_received {:enter, :SelectionSet, :selectionSet, :Field}
    assert_received {:enter, :Field, 0, nil}
    assert_received {:enter, :Name, :name, :Field}
    assert_received {:leave, :Name, :name, :Field}
    assert_received {:leave, :Field, 0, nil}
    assert_received {:enter, :InlineFragment, 1, nil}
    assert_received {:enter, :NamedType, :typeCondition, :InlineFragment}
    assert_received {:enter, :Name, :name, :NamedType}
    assert_received {:leave, :Name, :name, :NamedType}
    assert_received {:leave, :NamedType, :typeCondition, :InlineFragment}
    assert_received {:enter, :Directive, 0, nil}
    assert_received {:enter, :Name, :name, :Directive}
    assert_received {:leave, :Name, :name, :Directive}
    assert_received {:leave, :Directive, 0, nil}
    assert_received {:enter, :SelectionSet, :selectionSet, :InlineFragment}
    assert_received {:enter, :Field, 0, nil}
    assert_received {:enter, :Name, :name, :Field}
    assert_received {:leave, :Name, :name, :Field}
    assert_received {:enter, :SelectionSet, :selectionSet, :Field}
    assert_received {:enter, :Field, 0, nil}
    assert_received {:enter, :Name, :name, :Field}
    assert_received {:leave, :Name, :name, :Field}
    assert_received {:leave, :Field, 0, nil}
    assert_received {:enter, :Field, 1, nil}
    assert_received {:enter, :Name, :alias, :Field}
    assert_received {:leave, :Name, :alias, :Field}
    assert_received {:enter, :Name, :name, :Field}
    assert_received {:leave, :Name, :name, :Field}
    assert_received {:enter, :Argument, 0, nil}
    assert_received {:enter, :Name, :name, :Argument}
    assert_received {:leave, :Name, :name, :Argument}
    assert_received {:enter, :IntValue, :value, :Argument}
    assert_received {:leave, :IntValue, :value, :Argument}
    assert_received {:leave, :Argument, 0, nil}
    assert_received {:enter, :Argument, 1, nil}
    assert_received {:enter, :Name, :name, :Argument}
    assert_received {:leave, :Name, :name, :Argument}
    assert_received {:enter, :Variable, :value, :Argument}
    assert_received {:enter, :Name, :name, :Variable}
    assert_received {:leave, :Name, :name, :Variable}
    assert_received {:leave, :Variable, :value, :Argument}
    assert_received {:leave, :Argument, 1, nil}
    assert_received {:enter, :Directive, 0, nil}
    assert_received {:enter, :Name, :name, :Directive}
    assert_received {:leave, :Name, :name, :Directive}
    assert_received {:enter, :Argument, 0, nil}
    assert_received {:enter, :Name, :name, :Argument}
    assert_received {:leave, :Name, :name, :Argument}
    assert_received {:enter, :Variable, :value, :Argument}
    assert_received {:enter, :Name, :name, :Variable}
    assert_received {:leave, :Name, :name, :Variable}
    assert_received {:leave, :Variable, :value, :Argument}
    assert_received {:leave, :Argument, 0, nil}
    assert_received {:leave, :Directive, 0, nil}
    assert_received {:enter, :SelectionSet, :selectionSet, :Field}
    assert_received {:enter, :Field, 0, nil}
    assert_received {:enter, :Name, :name, :Field}
    assert_received {:leave, :Name, :name, :Field}
    assert_received {:leave, :Field, 0, nil}
    assert_received {:enter, :FragmentSpread, 1, nil}
    assert_received {:enter, :Name, :name, :FragmentSpread}
    assert_received {:leave, :Name, :name, :FragmentSpread}
    assert_received {:leave, :FragmentSpread, 1, nil}
    assert_received {:leave, :SelectionSet, :selectionSet, :Field}
    assert_received {:leave, :Field, 1, nil}
    assert_received {:leave, :SelectionSet, :selectionSet, :Field}
    assert_received {:leave, :Field, 0, nil}
    assert_received {:leave, :SelectionSet, :selectionSet, :InlineFragment}
    assert_received {:leave, :InlineFragment, 1, nil}
    assert_received {:leave, :SelectionSet, :selectionSet, :Field}
    assert_received {:leave, :Field, 0, nil}
    assert_received {:leave, :SelectionSet, :selectionSet, :OperationDefinition}
    assert_received {:leave, :OperationDefinition, 0, nil}
    assert_received {:enter, :OperationDefinition, 1, nil}
    assert_received {:enter, :Name, :name, :OperationDefinition}
    assert_received {:leave, :Name, :name, :OperationDefinition}
    assert_received {:enter, :SelectionSet, :selectionSet, :OperationDefinition}
    assert_received {:enter, :Field, 0, nil}
    assert_received {:enter, :Name, :name, :Field}
    assert_received {:leave, :Name, :name, :Field}
    assert_received {:enter, :Argument, 0, nil}
    assert_received {:enter, :Name, :name, :Argument}
    assert_received {:leave, :Name, :name, :Argument}
    assert_received {:enter, :IntValue, :value, :Argument}
    assert_received {:leave, :IntValue, :value, :Argument}
    assert_received {:leave, :Argument, 0, nil}
    assert_received {:enter, :Directive, 0, nil}
    assert_received {:enter, :Name, :name, :Directive}
    assert_received {:leave, :Name, :name, :Directive}
    assert_received {:leave, :Directive, 0, nil}
    assert_received {:enter, :SelectionSet, :selectionSet, :Field}
    assert_received {:enter, :Field, 0, nil}
    assert_received {:enter, :Name, :name, :Field}
    assert_received {:leave, :Name, :name, :Field}
    assert_received {:enter, :SelectionSet, :selectionSet, :Field}
    assert_received {:enter, :Field, 0, nil}
    assert_received {:enter, :Name, :name, :Field}
    assert_received {:leave, :Name, :name, :Field}
    assert_received {:leave, :Field, 0, nil}
    assert_received {:leave, :SelectionSet, :selectionSet, :Field}
    assert_received {:leave, :Field, 0, nil}
    assert_received {:leave, :SelectionSet, :selectionSet, :Field}
    assert_received {:leave, :Field, 0, nil}
    assert_received {:leave, :SelectionSet, :selectionSet, :OperationDefinition}
    assert_received {:leave, :OperationDefinition, 1, nil}
    assert_received {:enter, :FragmentDefinition, 2, nil}
    assert_received {:enter, :Name, :name, :FragmentDefinition}
    assert_received {:leave, :Name, :name, :FragmentDefinition}
    assert_received {:enter, :NamedType, :typeCondition, :FragmentDefinition}
    assert_received {:enter, :Name, :name, :NamedType}
    assert_received {:leave, :Name, :name, :NamedType}
    assert_received {:leave, :NamedType, :typeCondition, :FragmentDefinition}
    assert_received {:enter, :SelectionSet, :selectionSet, :FragmentDefinition}
    assert_received {:enter, :Field, 0, nil}
    assert_received {:enter, :Name, :name, :Field}
    assert_received {:leave, :Name, :name, :Field}
    assert_received {:enter, :Argument, 0, nil}
    assert_received {:enter, :Name, :name, :Argument}
    assert_received {:leave, :Name, :name, :Argument}
    assert_received {:enter, :Variable, :value, :Argument}
    assert_received {:enter, :Name, :name, :Variable}
    assert_received {:leave, :Name, :name, :Variable}
    assert_received {:leave, :Variable, :value, :Argument}
    assert_received {:leave, :Argument, 0, nil}
    assert_received {:enter, :Argument, 1, nil}
    assert_received {:enter, :Name, :name, :Argument}
    assert_received {:leave, :Name, :name, :Argument}
    assert_received {:enter, :Variable, :value, :Argument}
    assert_received {:enter, :Name, :name, :Variable}
    assert_received {:leave, :Name, :name, :Variable}
    assert_received {:leave, :Variable, :value, :Argument}
    assert_received {:leave, :Argument, 1, nil}
    assert_received {:enter, :Argument, 2, nil}
    assert_received {:enter, :Name, :name, :Argument}
    assert_received {:leave, :Name, :name, :Argument}
    assert_received {:enter, :ObjectValue, :value, :Argument}
    assert_received {:enter, :ObjectField, 0, nil}
    assert_received {:enter, :Name, :name, :ObjectField}
    assert_received {:leave, :Name, :name, :ObjectField}
    assert_received {:enter, :StringValue, :value, :ObjectField}
    assert_received {:leave, :StringValue, :value, :ObjectField}
    assert_received {:leave, :ObjectField, 0, nil}
    assert_received {:leave, :ObjectValue, :value, :Argument}
    assert_received {:leave, :Argument, 2, nil}
    assert_received {:leave, :Field, 0, nil}
    assert_received {:leave, :SelectionSet, :selectionSet, :FragmentDefinition}
    assert_received {:leave, :FragmentDefinition, 2, nil}
    assert_received {:enter, :OperationDefinition, 3, nil}
    assert_received {:enter, :SelectionSet, :selectionSet, :OperationDefinition}
    assert_received {:enter, :Field, 0, nil}
    assert_received {:enter, :Name, :name, :Field}
    assert_received {:leave, :Name, :name, :Field}
    assert_received {:enter, :Argument, 0, nil}
    assert_received {:enter, :Name, :name, :Argument}
    assert_received {:leave, :Name, :name, :Argument}
    assert_received {:enter, :BooleanValue, :value, :Argument}
    assert_received {:leave, :BooleanValue, :value, :Argument}
    assert_received {:leave, :Argument, 0, nil}
    assert_received {:enter, :Argument, 1, nil}
    assert_received {:enter, :Name, :name, :Argument}
    assert_received {:leave, :Name, :name, :Argument}
    assert_received {:enter, :BooleanValue, :value, :Argument}
    assert_received {:leave, :BooleanValue, :value, :Argument}
    assert_received {:leave, :Argument, 1, nil}
    assert_received {:leave, :Field, 0, nil}
    assert_received {:enter, :Field, 1, nil}
    assert_received {:enter, :Name, :name, :Field}
    assert_received {:leave, :Name, :name, :Field}
    assert_received {:leave, :Field, 1, nil}
    assert_received {:leave, :SelectionSet, :selectionSet, :OperationDefinition}
    assert_received {:leave, :OperationDefinition, 3, nil}
    assert_received {:leave, :Document, nil, nil}
  end
end
