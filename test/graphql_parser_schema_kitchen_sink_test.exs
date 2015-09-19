defmodule GraphqlParserSchemaKitchenSinkTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  test "Schema Kitchen Sink" do
    assert_parse """
      # Copyright (c) 2015, Facebook, Inc.

      type Foo implements Bar {
        one: Type
        two(argument: InputType!): Type
        three(argument: InputType, other: String): Int
        four(argument: String = "string"): String
        five(argument: [String] = ["string", "string"]): String
        six(argument: InputType = {key: "value"}): Type
      }

      interface Bar {
        one: Type
        four(argument: String = "string"): String
      }

      union Feed = Story | Article | Advert

      scalar CustomScalar

      enum Site {
        DESKTOP
        MOBILE
      }

      input InputType {
        key: String!
        answer: Int = 42
      }

      extend type Foo {
        seven(argument: [String]): Type
      }
    """,
    [kind: :Document, loc: [start: 0],
      definitions: [
        [kind: :ObjectTypeDefinition, loc: [start: 0],
          name: 'Foo',
          interfaces: [[kind: :NamedType, loc: [start: 0], name: 'Bar']],
          fields: [
            [kind: :FieldDefinition, loc: [start: 0],
              name: 'one',
              type: [kind: :NamedType, loc: [start: 0], name: 'Type']],
            [kind: :FieldDefinition, loc: [start: 0],
              name: 'two',
              arguments: [
                [kind: :InputValueDefinition, loc: [start: 0],
                  name: 'argument',
                  type: [kind: :NonNullType, loc: [start: 0],
                    type: [kind: :NamedType, loc: [start: 0], name: 'InputType']]]],
              type: [kind: :NamedType, loc: [start: 0], name: 'Type']],
            [kind: :FieldDefinition, loc: [start: 0],
              name: 'three',
              arguments: [
                [kind: :InputValueDefinition, loc: [start: 0],
                  name: 'argument',
                  type: [kind: :NamedType, loc: [start: 0], name: 'InputType']],
                [kind: :InputValueDefinition, loc: [start: 0],
                  name: 'other',
                  type: [kind: :NamedType, loc: [start: 0], name: 'String']]],
              type: [kind: :NamedType, loc: [start: 0], name: 'Int']],
            [kind: :FieldDefinition, loc: [start: 0],
              name: 'four',
              arguments: [
                [kind: :InputValueDefinition, loc: [start: 0],
                  name: 'argument',
                  type: [kind: :NamedType, loc: [start: 0], name: 'String'],
                  defaultValue: [kind: :StringValue, loc: [start: 0], value: '"string"']]],
              type: [kind: :NamedType, loc: [start: 0], name: 'String']],
            [kind: :FieldDefinition, loc: [start: 0],
              name: 'five',
              arguments: [
                [kind: :InputValueDefinition, loc: [start: 0],
                  name: 'argument',
                  type: [kind: :ListType, loc: [start: 0],
                    type: [kind: :NamedType, loc: [start: 0], name: 'String']],
                  defaultValue: [kind: :ListValue, loc: [start: 0],
                    values: [
                      [kind: :StringValue, loc: [start: 0], value: '"string"'],
                      [kind: :StringValue, loc: [start: 0], value: '"string"']]]]],
              type: [kind: :NamedType, loc: [start: 0], name: 'String']],
            [kind: :FieldDefinition, loc: [start: 0],
              name: 'six',
              arguments: [
                [kind: :InputValueDefinition, loc: [start: 0],
                  name: 'argument',
                  type: [kind: :NamedType, loc: [start: 0], name: 'InputType'],
                  defaultValue: [kind: :ObjectValue, loc: [start: 0],
                    fields: [
                      [kind: :ObjectField, loc: [start: 0],
                        name: 'key',
                        value: [kind: :StringValue, loc: [start: 0], value: '"value"']]]]]],
                  type: [kind: :NamedType, loc: [start: 0], name: 'Type']]]],

        [kind: :InterfaceTypeDefinition, loc: [start: 0],
          name: 'Bar',
          fields: [
            [kind: :FieldDefinition, loc: [start: 0],
              name: 'one',
              type: [kind: :NamedType, loc: [start: 0], name: 'Type']],
            [kind: :FieldDefinition, loc: [start: 0],
              name: 'four',
              arguments: [
                [kind: :InputValueDefinition, loc: [start: 0],
                  name: 'argument',
                  type: [kind: :NamedType, loc: [start: 0], name: 'String'],
                  defaultValue: [kind: :StringValue, loc: [start: 0], value: '"string"']]],
              type: [kind: :NamedType, loc: [start: 0], name: 'String']]]],

        [kind: :UnionTypeDefinition, loc: [start: 0],
          name: 'Feed',
          types: [
            [kind: :NamedType, loc: [start: 0], name: 'Story'],
            [kind: :NamedType, loc: [start: 0], name: 'Article'],
            [kind: :NamedType, loc: [start: 0], name: 'Advert']]],

        [kind: :ScalarTypeDefinition, loc: [start: 0],
          name: 'CustomScalar'],

        [kind: :EnumTypeDefinition, loc: [start: 0],
          name: 'Site',
          values: ['DESKTOP', 'MOBILE']],

        [kind: :InputObjectTypeDefinition, loc: [start: 0],
          name: 'InputType',
          fields: [
            [kind: :InputValueDefinition, loc: [start: 0],
              name: 'key',
              type: [kind: :NonNullType, loc: [start: 0],
                type: [kind: :NamedType, loc: [start: 0], name: 'String']]],
            [kind: :InputValueDefinition, loc: [start: 0],
              name: 'answer',
              type: [kind: :NamedType, loc: [start: 0], name: 'Int'],
              defaultValue: [kind: :IntValue, loc: [start: 0], value: 42]]]],

        [kind: :TypeExtensionDefinition, loc: [start: 0],
          definition: [kind: :ObjectTypeDefinition, loc: [start: 0],
            name: 'Foo',
            fields: [
              [kind: :FieldDefinition, loc: [start: 0],
                name: 'seven',
                arguments: [
                  [kind: :InputValueDefinition, loc: [start: 0],
                    name: 'argument',
                    type: [kind: :ListType, loc: [start: 0],
                      type: [kind: :NamedType, loc: [start: 0], name: 'String']]]],
                type: [kind: :NamedType, loc: [start: 0], name: 'Type']]]]]]]
  end
end
