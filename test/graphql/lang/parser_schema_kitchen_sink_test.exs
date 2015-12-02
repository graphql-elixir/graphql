defmodule GraphQL.Lang.Parser.SchemaKitchenSinkTest do
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
    %{definitions: [%{fields: [%{kind: :FieldDefinition, loc: %{start: 0},
          name: "one", type: %{kind: :NamedType, loc: %{start: 0}, name: "Type"}},
        %{arguments: [%{kind: :InputValueDefinition, loc: %{start: 0},
             name: "argument",
             type: %{kind: :NonNullType, loc: %{start: 0},
               type: %{kind: :NamedType, loc: %{start: 0}, name: "InputType"}}}],
          kind: :FieldDefinition, loc: %{start: 0}, name: "two",
          type: %{kind: :NamedType, loc: %{start: 0}, name: "Type"}},
        %{arguments: [%{kind: :InputValueDefinition, loc: %{start: 0},
             name: "argument",
             type: %{kind: :NamedType, loc: %{start: 0}, name: "InputType"}},
           %{kind: :InputValueDefinition, loc: %{start: 0}, name: "other",
             type: %{kind: :NamedType, loc: %{start: 0}, name: "String"}}],
          kind: :FieldDefinition, loc: %{start: 0}, name: "three",
          type: %{kind: :NamedType, loc: %{start: 0}, name: "Int"}},
        %{arguments: [%{defaultValue: %{kind: :StringValue, loc: %{start: 0},
               value: "string"}, kind: :InputValueDefinition, loc: %{start: 0},
             name: "argument",
             type: %{kind: :NamedType, loc: %{start: 0}, name: "String"}}],
          kind: :FieldDefinition, loc: %{start: 0}, name: "four",
          type: %{kind: :NamedType, loc: %{start: 0}, name: "String"}},
        %{arguments: [%{defaultValue: %{kind: :ListValue, loc: %{start: 0},
               values: [%{kind: :StringValue, loc: %{start: 0}, value: "string"},
                %{kind: :StringValue, loc: %{start: 0}, value: "string"}]},
             kind: :InputValueDefinition, loc: %{start: 0}, name: "argument",
             type: %{kind: :ListType, loc: %{start: 0},
               type: %{kind: :NamedType, loc: %{start: 0}, name: "String"}}}],
          kind: :FieldDefinition, loc: %{start: 0}, name: "five",
          type: %{kind: :NamedType, loc: %{start: 0}, name: "String"}},
        %{arguments: [%{defaultValue: %{fields: [%{kind: :ObjectField,
                  loc: %{start: 0}, name: "key",
                  value: %{kind: :StringValue, loc: %{start: 0},
                    value: "value"}}], kind: :ObjectValue, loc: %{start: 0}},
             kind: :InputValueDefinition, loc: %{start: 0}, name: "argument",
             type: %{kind: :NamedType, loc: %{start: 0}, name: "InputType"}}],
          kind: :FieldDefinition, loc: %{start: 0}, name: "six",
          type: %{kind: :NamedType, loc: %{start: 0}, name: "Type"}}],
       interfaces: [%{kind: :NamedType, loc: %{start: 0}, name: "Bar"}],
       kind: :ObjectTypeDefinition, loc: %{start: 0}, name: "Foo"},
     %{fields: [%{kind: :FieldDefinition, loc: %{start: 0}, name: "one",
          type: %{kind: :NamedType, loc: %{start: 0}, name: "Type"}},
        %{arguments: [%{defaultValue: %{kind: :StringValue, loc: %{start: 0},
               value: "string"}, kind: :InputValueDefinition, loc: %{start: 0},
             name: "argument",
             type: %{kind: :NamedType, loc: %{start: 0}, name: "String"}}],
          kind: :FieldDefinition, loc: %{start: 0}, name: "four",
          type: %{kind: :NamedType, loc: %{start: 0}, name: "String"}}],
       kind: :InterfaceTypeDefinition, loc: %{start: 0}, name: "Bar"},
     %{kind: :UnionTypeDefinition, loc: %{start: 0}, name: "Feed",
       types: [%{kind: :NamedType, loc: %{start: 0}, name: "Story"},
        %{kind: :NamedType, loc: %{start: 0}, name: "Article"},
        %{kind: :NamedType, loc: %{start: 0}, name: "Advert"}]},
     %{kind: :ScalarTypeDefinition, loc: %{start: 0}, name: "CustomScalar"},
     %{kind: :EnumTypeDefinition, loc: %{start: 0}, name: "Site",
       values: ["DESKTOP", "MOBILE"]},
     %{fields: [%{kind: :InputValueDefinition, loc: %{start: 0}, name: "key",
          type: %{kind: :NonNullType, loc: %{start: 0},
            type: %{kind: :NamedType, loc: %{start: 0}, name: "String"}}},
        %{defaultValue: %{kind: :IntValue, loc: %{start: 0}, value: 42},
          kind: :InputValueDefinition, loc: %{start: 0}, name: "answer",
          type: %{kind: :NamedType, loc: %{start: 0}, name: "Int"}}],
       kind: :InputObjectTypeDefinition, loc: %{start: 0}, name: "InputType"},
     %{definition: %{fields: [%{arguments: [%{kind: :InputValueDefinition,
               loc: %{start: 0}, name: "argument",
               type: %{kind: :ListType, loc: %{start: 0},
                 type: %{kind: :NamedType, loc: %{start: 0}, name: "String"}}}],
            kind: :FieldDefinition, loc: %{start: 0}, name: "seven",
            type: %{kind: :NamedType, loc: %{start: 0}, name: "Type"}}],
         kind: :ObjectTypeDefinition, loc: %{start: 0}, name: "Foo"},
       kind: :TypeExtensionDefinition, loc: %{start: 0}}], kind: :Document,
    loc: %{start: 0}}
  end
end
