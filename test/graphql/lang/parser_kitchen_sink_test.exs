defmodule GraphQL.Lang.Parser.KitchenSinkTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  test "Kitchen Sink" do
    assert_parse """
      # Copyright (c) 2015, Facebook, Inc.

      query queryName($foo: ComplexType, $site: Site = MOBILE) {
        whoever123is: node(id: [123, 456]) {
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
      """,
    %{definitions: [%{kind: :OperationDefinition, loc: %{start: 0},
       name: "queryName", operation: :query,
       selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
         selections: [%{alias: "whoever123is",
            arguments: [%{kind: :Argument, loc: %{start: 0}, name: "id",
               value: %{kind: :ListValue, loc: %{start: 0},
                 values: [%{kind: :IntValue, loc: %{start: 0}, value: 123},
                  %{kind: :IntValue, loc: %{start: 0}, value: 456}]}}],
            kind: :Field, loc: %{start: 0}, name: "node",
            selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
              selections: [%{kind: :Field, loc: %{start: 0}, name: "id"},
               %{directives: [%{kind: :Directive, loc: %{start: 0},
                    name: "defer"}], kind: :InlineFragment, loc: %{start: 0},
                 selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                   selections: [%{kind: :Field, loc: %{start: 0}, name: "field2",
                      selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                        selections: [%{kind: :Field, loc: %{start: 0},
                           name: "id"},
                         %{alias: "alias",
                           arguments: [%{kind: :Argument, loc: %{start: 0},
                              name: "first",
                              value: %{kind: :IntValue, loc: %{start: 0},
                                value: 10}},
                            %{kind: :Argument, loc: %{start: 0}, name: "after",
                              value: %{kind: :Variable, loc: %{start: 0},
                                name: "foo"}}],
                           directives: [%{arguments: [%{kind: :Argument,
                                 loc: %{start: 0}, name: "if",
                                 value: %{kind: :Variable, loc: %{start: 0},
                                   name: "foo"}}], kind: :Directive,
                              loc: %{start: 0}, name: "include"}], kind: :Field,
                           loc: %{start: 0}, name: "field1",
                           selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                             selections: [%{kind: :Field, loc: %{start: 0},
                                name: "id"},
                              %{kind: :FragmentSpread, loc: %{start: 0},
                                name: "frag"}]}}]}}]},
                 typeCondition: %{kind: :NamedType, loc: %{start: 0},
                   name: "User"}}]}}]},
       variableDefinitions: [%{kind: :VariableDefinition, loc: %{start: 0},
          type: %{kind: :NamedType, loc: %{start: 0}, name: "ComplexType"},
          variable: %{kind: :Variable, loc: %{start: 0}, name: "foo"}},
        %{defaultValue: %{kind: :EnumValue, loc: %{start: 0}, value: "MOBILE"},
          kind: :VariableDefinition, loc: %{start: 0},
          type: %{kind: :NamedType, loc: %{start: 0}, name: "Site"},
          variable: %{kind: :Variable, loc: %{start: 0}, name: "site"}}]},
     %{kind: :OperationDefinition, loc: %{start: 0}, name: "likeStory",
       operation: :mutation,
       selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
         selections: [%{arguments: [%{kind: :Argument, loc: %{start: 0},
               name: "story",
               value: %{kind: :IntValue, loc: %{start: 0}, value: 123}}],
            directives: [%{kind: :Directive, loc: %{start: 0}, name: "defer"}],
            kind: :Field, loc: %{start: 0}, name: "like",
            selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
              selections: [%{kind: :Field, loc: %{start: 0}, name: "story",
                 selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                   selections: [%{kind: :Field, loc: %{start: 0},
                      name: "id"}]}}]}}]}},
     %{kind: :FragmentDefinition, loc: %{start: 0}, name: "frag",
       selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
         selections: [%{arguments: [%{kind: :Argument, loc: %{start: 0},
               name: "size",
               value: %{kind: :Variable, loc: %{start: 0}, name: "size"}},
             %{kind: :Argument, loc: %{start: 0}, name: "bar",
               value: %{kind: :Variable, loc: %{start: 0}, name: "b"}},
             %{kind: :Argument, loc: %{start: 0}, name: "obj",
               value: %{fields: [%{kind: :ObjectField, loc: %{start: 0},
                    name: "key",
                    value: %{kind: :StringValue, loc: %{start: 0},
                      value: "value"}}], kind: :ObjectValue, loc: %{start: 0}}}],
            kind: :Field, loc: %{start: 0}, name: "foo"}]},
       typeCondition: %{kind: :NamedType, loc: %{start: 0}, name: "Friend"}},
     %{kind: :OperationDefinition, loc: %{start: 0}, operation: :query,
       selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
         selections: [%{arguments: [%{kind: :Argument, loc: %{start: 0},
               name: "truthy",
               value: %{kind: :BooleanValue, loc: %{start: 0}, value: true}},
             %{kind: :Argument, loc: %{start: 0}, name: "falsey",
               value: %{kind: :BooleanValue, loc: %{start: 0}, value: false}}],
            kind: :Field, loc: %{start: 0}, name: "unnamed"},
          %{kind: :Field, loc: %{start: 0}, name: "query"}]}}], kind: :Document,
    loc: %{start: 0}}
  end
end
