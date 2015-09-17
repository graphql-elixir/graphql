defmodule GraphqlParserKitchenSinkTest do
  use ExUnit.Case, async: true

  def assert_parse(input_string, expected_output) do
    assert GraphQL.parse(input_string) == expected_output
  end

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
        qry
      }
    """,
      [kind: :Document, loc: [start: 0],
        definitions: [[kind: :OperationDefinition, loc: [start: 0], operation: :query,
          name: 'queryName',
          variableDefinitions: [[kind: :VariableDefinition, loc: [start: 0],
            variable: [kind: :Variable, loc: [start: 0], name: 'foo'],
            type: [kind: :NamedType, loc: [start: 0], name: 'ComplexType']],
           [kind: :VariableDefinition, loc: [start: 0],
            variable: [kind: :Variable, loc: [start: 0], name: 'site'],
            type: [kind: :NamedType, loc: [start: 0], name: 'Site'],
            defaultValue: [kind: :EnumValue, loc: [start: 0], value: 'MOBILE']]],
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
           selections: [[kind: :Field, loc: [start: 0], alias: 'whoever123is', name: 'node',
             arguments: [[kind: :Argument, loc: [start: 0], name: 'id',
               value: [kind: :ListValue, loc: [start: 0],
                values: [[kind: :IntValue, loc: [start: 0], value: 123],
                 [kind: :IntValue, loc: [start: 0], value: 456]]]]],
             selectionSet: [kind: :SelectionSet, loc: [start: 0],
              selections: [[kind: :Field, loc: [start: 0], name: 'id'],
               [kind: :InlineFragment, loc: [start: 0],
                typeCondition: [kind: :NamedType, loc: [start: 0], name: 'User'],
                directives: [[kind: :Directive, loc: [start: 0], name: 'defer']],
                selectionSet: [kind: :SelectionSet, loc: [start: 0],
                 selections: [[kind: :Field, loc: [start: 0], name: 'field2',
                   selectionSet: [kind: :SelectionSet, loc: [start: 0],
                    selections: [[kind: :Field, loc: [start: 0], name: 'id'],
                     [kind: :Field, loc: [start: 0], alias: 'alias', name: 'field1',
                      arguments: [[kind: :Argument, loc: [start: 0], name: 'first',
                        value: [kind: :IntValue, loc: [start: 0], value: 10]],
                       [kind: :Argument, loc: [start: 0], name: 'after',
                        value: [kind: :Variable, loc: [start: 0], name: 'foo']]],
                      directives: [[kind: :Directive, loc: [start: 0], name: 'include',
                        arguments: [[kind: :Argument, loc: [start: 0], name: 'if',
                          value: [kind: :Variable, loc: [start: 0], name: 'foo']]]]],
                      selectionSet: [kind: :SelectionSet, loc: [start: 0],
                       selections: [[kind: :Field, loc: [start: 0], name: 'id'],
                        [kind: :FragmentSpread, loc: [start: 0], name: 'frag']]]]]]]]]]]]]]]],
         [kind: :OperationDefinition, loc: [start: 0], operation: :mutation, name: 'likeStory',
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
           selections: [[kind: :Field, loc: [start: 0], name: 'like',
             arguments: [[kind: :Argument, loc: [start: 0], name: 'story',
               value: [kind: :IntValue, loc: [start: 0], value: 123]]],
             directives: [[kind: :Directive, loc: [start: 0], name: 'defer']],
             selectionSet: [kind: :SelectionSet, loc: [start: 0],
              selections: [[kind: :Field, loc: [start: 0], name: 'story',
                selectionSet: [kind: :SelectionSet, loc: [start: 0],
                 selections: [[kind: :Field, loc: [start: 0], name: 'id']]]]]]]]]],
         [kind: :FragmentDefinition, loc: [start: 0], name: 'frag',
          typeCondition: [kind: :NamedType, loc: [start: 0], name: 'Friend'],
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
           selections: [[kind: :Field, loc: [start: 0], name: 'foo',
             arguments: [[kind: :Argument, loc: [start: 0], name: 'size',
               value: [kind: :Variable, loc: [start: 0], name: 'size']],
              [kind: :Argument, loc: [start: 0], name: 'bar',
               value: [kind: :Variable, loc: [start: 0], name: 'b']],
              [kind: :Argument, loc: [start: 0], name: 'obj',
               value: [kind: :ObjectValue, loc: [start: 0],
                fields: [[kind: :ObjectField, loc: [start: 0], name: 'key',
                  value: [kind: :StringValue, loc: [start: 0], value: '"value"']]]]]]]]]],
         [kind: :OperationDefinition, loc: [start: 0], operation: :query,
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
           selections: [[kind: :Field, loc: [start: 0], name: 'unnamed',
             arguments: [[kind: :Argument, loc: [start: 0], name: 'truthy',
               value: [kind: :BooleanValue, loc: [start: 0], value: true]],
              [kind: :Argument, loc: [start: 0], name: 'falsey',
               value: [kind: :BooleanValue, loc: [start: 0], value: false]]]],
            [kind: :Field, loc: [start: 0], name: 'qry']]]]]]
  end
end
