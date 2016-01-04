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
         name: %{kind: :Name, loc: %{start: 0}, value: "queryName"},
         operation: :query,
         selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
           selections: [%{alias: %{kind: :Name, loc: %{start: 0}, value: "whoever123is"},
              arguments: [%{kind: :Argument, loc: %{start: 0},
                 name: %{kind: :Name, loc: %{start: 0}, value: "id"},
                 value: %{kind: :ListValue, loc: %{start: 0},
                   values: [%{kind: :IntValue, loc: %{start: 0},
                      value: 123},
                    %{kind: :IntValue, loc: %{start: 0},
                      value: 456}]}}], kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "node"},
              selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                selections: [%{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0}, value: "id"}},
                 %{directives: [%{kind: :Directive, loc: %{start: 0},
                      name: %{kind: :Name, loc: %{start: 0}, value: "defer"}}], kind: :InlineFragment,
                   loc: %{start: 0},
                   selectionSet: %{kind: :SelectionSet,
                     loc: %{start: 0},
                     selections: [%{kind: :Field, loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "field2"},
                        selectionSet: %{kind: :SelectionSet,
                          loc: %{start: 0},
                          selections: [%{kind: :Field, loc: %{start: 0},
                             name: %{kind: :Name, loc: %{start: 0},
                               value: "id"}},
                           %{alias: %{kind: :Name, loc: %{start: 0}, value: "alias"},
                             arguments: [%{kind: :Argument,
                                loc: %{start: 0},
                                name: %{kind: :Name, loc: %{start: 0},
                                  value: "first"},
                                value: %{kind: :IntValue,
                                  loc: %{start: 0}, value: 10}},
                              %{kind: :Argument, loc: %{start: 0},
                                name: %{kind: :Name, loc: %{start: 0},
                                  value: "after"},
                                value: %{kind: :Variable,
                                  loc: %{start: 0},
                                  name: %{kind: :Name, loc: %{start: 0},
                                    value: "foo"}}}],
                             directives: [%{arguments: [%{kind: :Argument,
                                   loc: %{start: 0},
                                   name: %{kind: :Name,
                                     loc: %{start: 0}, value: "if"},
                                   value: %{kind: :Variable,
                                     loc: %{start: 0},
                                     name: %{kind: :Name,
                                       loc: %{start: 0},
                                       value: "foo"}}}],
                                kind: :Directive, loc: %{start: 0},
                                name: %{kind: :Name, loc: %{start: 0},
                                  value: "include"}}], kind: :Field,
                             loc: %{start: 0},
                             name: %{kind: :Name, loc: %{start: 0},
                               value: "field1"},
                             selectionSet: %{kind: :SelectionSet,
                               loc: %{start: 0},
                               selections: [%{kind: :Field,
                                  loc: %{start: 0},
                                  name: %{kind: :Name, loc: %{start: 0},
                                    value: "id"}},
                                %{kind: :FragmentSpread,
                                  loc: %{start: 0},
                                  name: %{kind: :Name, loc: %{start: 0},
                                    value: "frag"}}]}}]}}]},
                   typeCondition: %{kind: :NamedType, loc: %{start: 0},
                     name: %{kind: :Name, loc: %{start: 0},
                       value: "User"}}}]}}]},
         variableDefinitions: [%{kind: :VariableDefinition,
            loc: %{start: 0},
            type: %{kind: :NamedType, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0},
                value: "ComplexType"}},
            variable: %{kind: :Variable, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "foo"}}},
          %{defaultValue: %{kind: :EnumValue, loc: %{start: 0},
              value: "MOBILE"}, kind: :VariableDefinition,
            loc: %{start: 0},
            type: %{kind: :NamedType, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "Site"}},
            variable: %{kind: :Variable, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "site"}}}]},
       %{kind: :OperationDefinition, loc: %{start: 0},
         name: %{kind: :Name, loc: %{start: 0}, value: "likeStory"},
         operation: :mutation,
         selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
           selections: [%{arguments: [%{kind: :Argument,
                 loc: %{start: 0},
                 name: %{kind: :Name, loc: %{start: 0}, value: "story"},
                 value: %{kind: :IntValue, loc: %{start: 0},
                   value: 123}}],
              directives: [%{kind: :Directive, loc: %{start: 0},
                 name: %{kind: :Name, loc: %{start: 0}, value: "defer"}}], kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "like"},
              selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                selections: [%{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "story"},
                   selectionSet: %{kind: :SelectionSet,
                     loc: %{start: 0},
                     selections: [%{kind: :Field, loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "id"}}]}}]}}]}},
       %{kind: :FragmentDefinition, loc: %{start: 0},
         name: %{kind: :Name, loc: %{start: 0}, value: "frag"},
         selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
           selections: [%{arguments: [%{kind: :Argument,
                 loc: %{start: 0},
                 name: %{kind: :Name, loc: %{start: 0}, value: "size"},
                 value: %{kind: :Variable, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "size"}}},
               %{kind: :Argument, loc: %{start: 0},
                 name: %{kind: :Name, loc: %{start: 0}, value: "bar"},
                 value: %{kind: :Variable, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0}, value: "b"}}},
               %{kind: :Argument, loc: %{start: 0},
                 name: %{kind: :Name, loc: %{start: 0}, value: "obj"},
                 value: %{fields: [%{kind: :ObjectField,
                      loc: %{start: 0},
                      name: %{kind: :Name, loc: %{start: 0},
                        value: "key"},
                      value: %{kind: :StringValue, loc: %{start: 0},
                        value: "value"}}], kind: :ObjectValue,
                   loc: %{start: 0}}}], kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "foo"}}]},
         typeCondition: %{kind: :NamedType, loc: %{start: 0},
           name: %{kind: :Name, loc: %{start: 0}, value: "Friend"}}},
       %{kind: :OperationDefinition, loc: %{start: 0},
         operation: :query,
         selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
           selections: [%{arguments: [%{kind: :Argument,
                 loc: %{start: 0},
                 name: %{kind: :Name, loc: %{start: 0},
                   value: "truthy"},
                 value: %{kind: :BooleanValue, loc: %{start: 0},
                   value: true}},
               %{kind: :Argument, loc: %{start: 0},
                 name: %{kind: :Name, loc: %{start: 0},
                   value: "falsey"},
                 value: %{kind: :BooleanValue, loc: %{start: 0},
                   value: false}}], kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "unnamed"}},
            %{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0},
                value: "query"}}]}}], kind: :Document,
      loc: %{start: 0}}
  end
end
