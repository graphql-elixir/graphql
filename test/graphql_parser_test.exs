defmodule GraphqlParserTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  test "simple selection set" do
    assert_parse "{ hero }",
      [kind: :Document, loc: [start: 0],
        definitions: [[kind: :OperationDefinition, loc: [start: 0],
          operation: :query,
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
            selections: [[kind: :Field, loc: [start: 0], name: "hero"]]]]]]
  end

  test "multiple definitions" do
    assert_parse "{ hero } { ship }",
      [kind: :Document,
        loc: [start: 0],
        definitions: [
          [kind: :OperationDefinition,
            loc: [start: 0],
            operation: :query,
            selectionSet: [
              kind: :SelectionSet,
              loc: [start: 0],
              selections: [[kind: :Field, loc: [start: 0], name: "hero"]]]],
          [kind: :OperationDefinition,
            loc: [start: 0],
            operation: :query,
            selectionSet: [
              kind: :SelectionSet,
              loc: [start: 0],
              selections: [[kind: :Field, loc: [start: 0], name: "ship"]]]]
        ]
      ]
  end

  test "aliased selection set" do
    assert_parse "{alias: hero}",
      [kind: :Document, loc: [start: 0],
        definitions: [
          [kind: :OperationDefinition, loc: [start: 0],
            operation: :query,
            selectionSet: [
              kind: :SelectionSet, loc: [start: 0],
              selections: [
                [kind: :Field, loc: [start: 0], alias: "alias", name: "hero" ]]]]]]
  end

  test "multiple selection set" do
    assert_parse "{ id firstName lastName }",
      [kind: :Document, loc: [start: 0],
        definitions: [
          [kind: :OperationDefinition, loc: [start: 0],
            operation: :query,
            selectionSet: [
              kind: :SelectionSet, loc: [start: 0],
              selections: [
                [kind: :Field, loc: [start: 0], name: "id" ],
                [kind: :Field, loc: [start: 0], name: "firstName" ],
                [kind: :Field, loc: [start: 0], name: "lastName" ]
              ]]]]]
  end

  test "nested selection set" do
    assert_parse "{ user { name } }",
      [kind: :Document, loc: [start: 0],
        definitions: [
          [kind: :OperationDefinition, loc: [start: 0],
            operation: :query,
            selectionSet: [
              kind: :SelectionSet, loc: [start: 0],
              selections: [
                [kind: :Field, loc: [start: 0],
                  name: "user",
                  selectionSet: [
                    kind: :SelectionSet, loc: [start: 0],
                    selections: [
                      [kind: :Field, loc: [start: 0],
                        name: "name"]]]]]]]]]
  end

  test "named query with nested selection set" do
    assert_parse "query myQuery { user { name } }",
      [kind: :Document, loc: [start: 0],
        definitions: [
          [kind: :OperationDefinition, loc: [start: 0],
            operation: :query,
            name: "myQuery",
            selectionSet: [
              kind: :SelectionSet, loc: [start: 0],
              selections: [
                [kind: :Field, loc: [start: 0],
                  name: "user",
                  selectionSet: [
                    kind: :SelectionSet, loc: [start: 0],
                    selections: [
                      [kind: :Field, loc: [start: 0],
                        name: "name"]]]]]]]]]
  end

  test "named mutation with nested selection set" do
    assert_parse "mutation myMutation { user { name } }",
      [kind: :Document, loc: [start: 0],
        definitions: [
          [kind: :OperationDefinition, loc: [start: 0],
            operation: :mutation,
            name: "myMutation",
            selectionSet: [
              kind: :SelectionSet, loc: [start: 0],
              selections: [
                [kind: :Field, loc: [start: 0],
                  name: "user",
                  selectionSet: [
                    kind: :SelectionSet, loc: [start: 0],
                    selections: [
                      [kind: :Field, loc: [start: 0],
                        name: "name"]]]]]]]]]
  end

  test "nested selection set with arguments" do
    assert_parse "{ user(id: 4) { name ( thing : \"abc\" ) } }",
      [kind: :Document, loc: [start: 0],
        definitions: [
          [kind: :OperationDefinition, loc: [start: 0],
            operation: :query,
            selectionSet: [
              kind: :SelectionSet, loc: [start: 0],
              selections: [
                [kind: :Field, loc: [start: 0],
                  name: "user",
                  arguments: [[kind: :Argument, loc: [start: 0],
                    name: "id",
                    value: [kind: :IntValue, loc: [start: 0],
                      value: 4]]],
                  selectionSet: [
                    kind: :SelectionSet, loc: [start: 0],
                    selections: [
                      [kind: :Field, loc: [start: 0],
                        name: "name",
                        arguments: [[kind: :Argument, loc: [start: 0],
                          name: "thing",
                          value: [kind: :StringValue, loc: [start: 0],
                            value: "abc"]]]]]]]]]]]]
  end

  test "aliased nested selection set with arguments" do
    assert_parse "{ alias: user(id: 4) { alias2 : name ( thing : \"abc\" ) } }",
      [kind: :Document, loc: [start: 0],
        definitions: [
          [kind: :OperationDefinition, loc: [start: 0],
            operation: :query,
            selectionSet: [
              kind: :SelectionSet, loc: [start: 0],
              selections: [
                [kind: :Field, loc: [start: 0],
                  alias: "alias",
                  name: "user",
                  arguments: [[kind: :Argument, loc: [start: 0],
                    name: "id",
                    value: [kind: :IntValue, loc: [start: 0],
                      value: 4]]],
                  selectionSet: [
                    kind: :SelectionSet, loc: [start: 0],
                    selections: [
                      [kind: :Field, loc: [start: 0],
                        alias: "alias2",
                        name: "name",
                        arguments: [[kind: :Argument, loc: [start: 0],
                          name: "thing",
                          value: [kind: :StringValue, loc: [start: 0],
                            value: "abc"]]]]]]]]]]]]
  end

  test "FragmentSpread" do
    assert_parse "query myQuery { ...fragSpread }",
      [kind: :Document, loc: [start: 0],
        definitions: [[kind: :OperationDefinition, loc: [start: 0],
          operation: :query,
          name: "myQuery",
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
            selections: [[kind: :FragmentSpread, loc: [start: 0],
              name: "fragSpread"]]]]]]
  end

  test "FragmentSpread with Directive" do
    assert_parse "query myQuery { ...fragSpread @include(if: true) }",
      [kind: :Document, loc: [start: 0],
        definitions: [[kind: :OperationDefinition, loc: [start: 0],
          operation: :query,
          name: "myQuery",
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
            selections: [[kind: :FragmentSpread, loc: [start: 0],
              name: "fragSpread",
              directives: [[kind: :Directive, loc: [start: 0],
                name: "include",
                arguments: [[kind: :Argument, loc: [start: 0],
                  name: "if",
                  value: [kind: :BooleanValue, loc: [start: 0],
                    value: true]]]]]]]]]]]
  end

  test "VariableDefinition with DefaultValue" do
    assert_parse "query myQuery($size: Int = 10) { id }",
      [kind: :Document, loc: [start: 0],
        definitions: [[kind: :OperationDefinition, loc: [start: 0],
          operation: :query,
          name: "myQuery",
          variableDefinitions: [[kind: :VariableDefinition, loc: [start: 0],
            variable: [kind: :Variable, loc: [start: 0],
              name: "size"],
            type: [kind: :NamedType, loc: [start: 0],
              name: "Int"],
            defaultValue: [kind: :IntValue, loc: [start: 0],
              value: 10]]],
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
           selections: [[kind: :Field, loc: [start: 0],
            name: "id"]]]]]]
  end

  test "Multiple VariableDefinition with DefaultValue (NonNullType, ListType, Variable)" do
    assert_parse "query myQuery($x: Int! = 7, $y: [Int], $z: Some = $var) { id }",
      [kind: :Document, loc: [start: 0],
        definitions: [[kind: :OperationDefinition, loc: [start: 0], operation: :query,
          name: "myQuery",
          variableDefinitions: [
            [kind: :VariableDefinition, loc: [start: 0],
              variable: [kind: :Variable, loc: [start: 0],
                name: "x"],
              type: [kind: :NonNullType, loc: [start: 0],
                type: [kind: :NamedType, loc: [start: 0],
                  name: "Int"]],
              defaultValue: [kind: :IntValue, loc: [start: 0],
                value: 7]],
            [kind: :VariableDefinition, loc: [start: 0],
              variable: [kind: :Variable, loc: [start: 0],
                name: "y"],
              type: [kind: :ListType, loc: [start: 0],
                type: [kind: :NamedType, loc: [start: 0],
                  name: "Int"]]],
            [kind: :VariableDefinition, loc: [start: 0],
              variable: [kind: :Variable, loc: [start: 0],
                name: "z"],
              type: [kind: :NamedType, loc: [start: 0],
                name: "Some"],
              defaultValue: [kind: :Variable, loc: [start: 0],
                name: "var"]]],
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
            selections: [[kind: :Field, loc: [start: 0],
              name: "id"]]]]]]
  end

  test "Multiple VariableDefinition with DefaultValue (EnumValue ListValue) and Directives" do
    assert_parse "query myQuery($x: Int! = ENUM, $y: [Int] = [1, 2]) @directive(num: 1.23, a: {b: 1, c: 2}) { id }",
      [kind: :Document, loc: [start: 0],
        definitions: [[kind: :OperationDefinition, loc: [start: 0],
          operation: :query,
          name: "myQuery",
          variableDefinitions: [
            [kind: :VariableDefinition, loc: [start: 0],
              variable: [kind: :Variable, loc: [start: 0], name: "x"],
              type: [kind: :NonNullType, loc: [start: 0],
                type: [kind: :NamedType, loc: [start: 0], name: "Int"]],
              defaultValue: [kind: :EnumValue, loc: [start: 0], value: "ENUM"]],
            [kind: :VariableDefinition, loc: [start: 0],
              variable: [kind: :Variable, loc: [start: 0], name: "y"],
              type: [kind: :ListType, loc: [start: 0],
                type: [kind: :NamedType, loc: [start: 0], name: "Int"]],
              defaultValue: [kind: :ListValue, loc: [start: 0],
                values: [
                  [kind: :IntValue, loc: [start: 0], value: 1],
                  [kind: :IntValue, loc: [start: 0], value: 2]]]]],
          directives: [
            [kind: :Directive, loc: [start: 0],
              name: "directive",
              arguments: [
                [kind: :Argument, loc: [start: 0],
                  name: "num",
                  value: [kind: :FloatValue, loc: [start: 0], value: 1.23]],
            [kind: :Argument, loc: [start: 0], name: "a",
              value: [kind: :ObjectValue, loc: [start: 0],
                fields: [
                  [kind: :ObjectField, loc: [start: 0], name: "b",
                    value: [kind: :IntValue, loc: [start: 0], value: 1]],
                  [kind: :ObjectField, loc: [start: 0], name: "c",
                    value: [kind: :IntValue, loc: [start: 0], value: 2]]]]]]]],
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
           selections: [[kind: :Field, loc: [start: 0], name: "id"]]]]]]
  end

  test "FragmentDefinition" do
    assert_parse "fragment friends on User { id }",
      [kind: :Document, loc: [start: 0],
        definitions: [[kind: :FragmentDefinition, loc: [start: 0], name: "friends",
          typeCondition: [kind: :NamedType, loc: [start: 0], name: "User"],
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
            selections: [[kind: :Field, loc: [start: 0], name: "id"]]]]]]
  end

  test "InlineFragment" do
    assert_parse "{ user { name, ... on Person { age } } }",
      [kind: :Document, loc: [start: 0],
        definitions: [[kind: :OperationDefinition, loc: [start: 0], operation: :query,
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
            selections: [[kind: :Field, loc: [start: 0], name: "user",
              selectionSet: [kind: :SelectionSet, loc: [start: 0],
                selections: [
                  [kind: :Field, loc: [start: 0], name: "name"],
                  [kind: :InlineFragment, loc: [start: 0],
                    typeCondition: [kind: :NamedType, loc: [start: 0], name: "Person"],
                    selectionSet: [kind: :SelectionSet, loc: [start: 0],
                      selections: [[kind: :Field, loc: [start: 0], name: "age"]]]]]]]]]]]]
  end

  test "ObjectTypeDefinition" do
    assert_parse "type Human implements Character, Entity { id: String! friends: [Character] }",
      [kind: :Document, loc: [start: 0],
        definitions: [
          [kind: :ObjectTypeDefinition, loc: [start: 0], name: "Human",
            interfaces: [
              [kind: :NamedType, loc: [start: 0], name: "Character"],
              [kind: :NamedType, loc: [start: 0], name: "Entity"]],
            fields: [
              [kind: :FieldDefinition, loc: [start: 0],
                name: "id",
                type: [kind: :NonNullType, loc: [start: 0],
                  type: [kind: :NamedType, loc: [start: 0], name: "String"]]],
              [kind: :FieldDefinition, loc: [start: 0], name: "friends",
                type: [kind: :ListType, loc: [start: 0],
                  type: [kind: :NamedType, loc: [start: 0], name: "Character"]]]]]]]
  end

  test "ObjectTypeDefinition with Arguments" do
    assert_parse "type Query { hero(episode: Episode): Character human(id: String! name: String): Human }",
      [kind: :Document, loc: [start: 0],
        definitions: [
          [kind: :ObjectTypeDefinition, loc: [start: 0],
            name: "Query",
            fields: [
              [kind: :FieldDefinition, loc: [start: 0],
                name: "hero",
                arguments: [
                  [kind: :InputValueDefinition, loc: [start: 0],
                    name: "episode",
                    type: [kind: :NamedType, loc: [start: 0], name: "Episode"]]],
                type: [kind: :NamedType, loc: [start: 0], name: "Character"]],
              [kind: :FieldDefinition, loc: [start: 0],
                name: "human",
                arguments: [
                  [kind: :InputValueDefinition, loc: [start: 0],
                    name: "id",
                    type: [kind: :NonNullType, loc: [start: 0],
                      type: [kind: :NamedType, loc: [start: 0], name: "String"]]],
                  [kind: :InputValueDefinition, loc: [start: 0], name: "name",
                    type: [kind: :NamedType, loc: [start: 0], name: "String"]]],
                type: [kind: :NamedType, loc: [start: 0], name: "Human"]]]]]]
  end

  test "InterfaceTypeDefinition" do
    assert_parse "interface Node { id: ID }",
      [kind: :Document, loc: [start: 0],
        definitions: [
          [kind: :InterfaceTypeDefinition, loc: [start: 0],
            name: "Node",
            fields: [
              [kind: :FieldDefinition, loc: [start: 0],
                name: "id",
                type: [kind: :NamedType, loc: [start: 0], name: "ID"]]]]]]
  end

  test "UnionTypeDefinition" do
    assert_parse "union Actor = User | Business",
      [kind: :Document, loc: [start: 0],
        definitions: [
          [kind: :UnionTypeDefinition, loc: [start: 0],
            name: "Actor",
            types: [
              [kind: :NamedType, loc: [start: 0], name: "User"],
              [kind: :NamedType, loc: [start: 0], name: "Business"]]]]]
  end

  test "ScalarTypeDefinition" do
    assert_parse "scalar DateTime",
      [kind: :Document, loc: [start: 0],
        definitions: [
          [kind: :ScalarTypeDefinition, loc: [start: 0],
            name: "DateTime"]]]
  end

  test "EnumTypeDefinition" do
    assert_parse "enum Direction { NORTH EAST SOUTH WEST }",
      [kind: :Document, loc: [start: 0],
        definitions: [
          [kind: :EnumTypeDefinition, loc: [start: 0],
            name: "Direction",
            values: ["NORTH", "EAST", "SOUTH", "WEST"]]]]
  end

  test "InputObjectTypeDefinition" do
    assert_parse "input Point2D { x: Float y: Float }",
      [kind: :Document, loc: [start: 0],
        definitions: [
          [kind: :InputObjectTypeDefinition, loc: [start: 0],
            name: "Point2D",
            fields: [
              [kind: :InputValueDefinition, loc: [start: 0], name: "x",
                type: [kind: :NamedType, loc: [start: 0], name: "Float"]],
              [kind: :InputValueDefinition, loc: [start: 0], name: "y",
                type: [kind: :NamedType, loc: [start: 0], name: "Float"]]]]]]
  end

  test "TypeExtensionDefinition" do
    assert_parse "extend type Story { isHiddenLocally: Boolean }",
      [kind: :Document, loc: [start: 0],
        definitions: [
          [kind: :TypeExtensionDefinition, loc: [start: 0],
            definition: [kind: :ObjectTypeDefinition, loc: [start: 0],
              name: "Story",
              fields: [
                [kind: :FieldDefinition, loc: [start: 0],
                  name: "isHiddenLocally",
                  type: [kind: :NamedType, loc: [start: 0], name: "Boolean"]]]]]]]
  end

  test "Use reserved words as fields" do
    assert_parse "{ query mutation fragment on type implements interface union scalar enum input extend null }",
      [kind: :Document, loc: [start: 0],
        definitions: [[kind: :OperationDefinition, loc: [start: 0],
          operation: :query,
          selectionSet: [kind: :SelectionSet, loc: [start: 0],
            selections: [
              [kind: :Field, loc: [start: 0], name: "query"],
              [kind: :Field, loc: [start: 0], name: "mutation"],
              [kind: :Field, loc: [start: 0], name: "fragment"],
              [kind: :Field, loc: [start: 0], name: "on"],
              [kind: :Field, loc: [start: 0], name: "type"],
              [kind: :Field, loc: [start: 0], name: "implements"],
              [kind: :Field, loc: [start: 0], name: "interface"],
              [kind: :Field, loc: [start: 0], name: "union"],
              [kind: :Field, loc: [start: 0], name: "scalar"],
              [kind: :Field, loc: [start: 0], name: "enum"],
              [kind: :Field, loc: [start: 0], name: "input"],
              [kind: :Field, loc: [start: 0], name: "extend"],
              [kind: :Field, loc: [start: 0], name: "null"]]]]]]

  end
end
