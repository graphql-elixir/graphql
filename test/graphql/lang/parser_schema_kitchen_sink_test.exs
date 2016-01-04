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
      %{definitions: [%{fields: [%{kind: :FieldDefinition,
          loc: %{start: 0},
          name: %{kind: :Name, loc: %{start: 0}, value: "one"},
          type: %{kind: :NamedType, loc: %{start: 0},
            name: %{kind: :Name, loc: %{start: 0}, value: "Type"}}},
        %{arguments: [%{kind: :InputValueDefinition, loc: %{start: 0},
             name: %{kind: :Name, loc: %{start: 0},
               value: "argument"},
             type: %{kind: :NonNullType, loc: %{start: 0},
               type: %{kind: :NamedType, loc: %{start: 0},
                 name: %{kind: :Name, loc: %{start: 0},
                   value: "InputType"}}}}], kind: :FieldDefinition,
          loc: %{start: 0},
          name: %{kind: :Name, loc: %{start: 0}, value: "two"},
          type: %{kind: :NamedType, loc: %{start: 0},
            name: %{kind: :Name, loc: %{start: 0}, value: "Type"}}},
        %{arguments: [%{kind: :InputValueDefinition, loc: %{start: 0},
             name: %{kind: :Name, loc: %{start: 0},
               value: "argument"},
             type: %{kind: :NamedType, loc: %{start: 0},
               name: %{kind: :Name, loc: %{start: 0},
                 value: "InputType"}}},
           %{kind: :InputValueDefinition, loc: %{start: 0},
             name: %{kind: :Name, loc: %{start: 0}, value: "other"},
             type: %{kind: :NamedType, loc: %{start: 0},
               name: %{kind: :Name, loc: %{start: 0},
                 value: "String"}}}], kind: :FieldDefinition,
          loc: %{start: 0},
          name: %{kind: :Name, loc: %{start: 0}, value: "three"},
          type: %{kind: :NamedType, loc: %{start: 0},
            name: %{kind: :Name, loc: %{start: 0}, value: "Int"}}},
        %{arguments: [%{defaultValue: %{kind: :StringValue,
               loc: %{start: 0}, value: "string"},
             kind: :InputValueDefinition, loc: %{start: 0},
             name: %{kind: :Name, loc: %{start: 0},
               value: "argument"},
             type: %{kind: :NamedType, loc: %{start: 0},
               name: %{kind: :Name, loc: %{start: 0},
                 value: "String"}}}], kind: :FieldDefinition,
          loc: %{start: 0},
          name: %{kind: :Name, loc: %{start: 0}, value: "four"},
          type: %{kind: :NamedType, loc: %{start: 0},
            name: %{kind: :Name, loc: %{start: 0}, value: "String"}}},
        %{arguments: [%{defaultValue: %{kind: :ListValue,
               loc: %{start: 0},
               values: [%{kind: :StringValue, loc: %{start: 0},
                  value: "string"},
                %{kind: :StringValue, loc: %{start: 0},
                  value: "string"}]}, kind: :InputValueDefinition,
             loc: %{start: 0},
             name: %{kind: :Name, loc: %{start: 0},
               value: "argument"},
             type: %{kind: :ListType, loc: %{start: 0},
               type: %{kind: :NamedType, loc: %{start: 0},
                 name: %{kind: :Name, loc: %{start: 0},
                   value: "String"}}}}], kind: :FieldDefinition,
          loc: %{start: 0},
          name: %{kind: :Name, loc: %{start: 0}, value: "five"},
          type: %{kind: :NamedType, loc: %{start: 0},
            name: %{kind: :Name, loc: %{start: 0}, value: "String"}}},
        %{arguments: [%{defaultValue: %{fields: [%{kind: :ObjectField,
                  loc: %{start: 0},
                  name: %{kind: :Name, loc: %{start: 0},
                    value: "key"},
                  value: %{kind: :StringValue, loc: %{start: 0},
                    value: "value"}}], kind: :ObjectValue,
               loc: %{start: 0}}, kind: :InputValueDefinition,
             loc: %{start: 0},
             name: %{kind: :Name, loc: %{start: 0},
               value: "argument"},
             type: %{kind: :NamedType, loc: %{start: 0},
               name: %{kind: :Name, loc: %{start: 0},
                 value: "InputType"}}}], kind: :FieldDefinition,
          loc: %{start: 0},
          name: %{kind: :Name, loc: %{start: 0}, value: "six"},
          type: %{kind: :NamedType, loc: %{start: 0},
            name: %{kind: :Name, loc: %{start: 0}, value: "Type"}}}],
       interfaces: [%{kind: :NamedType, loc: %{start: 0},
          name: %{kind: :Name, loc: %{start: 0}, value: "Bar"}}],
       kind: :ObjectTypeDefinition, loc: %{start: 0},
       name: %{kind: :Name, loc: %{start: 0}, value: "Foo"}},
     %{fields: [%{kind: :FieldDefinition, loc: %{start: 0},
          name: %{kind: :Name, loc: %{start: 0}, value: "one"},
          type: %{kind: :NamedType, loc: %{start: 0},
            name: %{kind: :Name, loc: %{start: 0}, value: "Type"}}},
        %{arguments: [%{defaultValue: %{kind: :StringValue,
               loc: %{start: 0}, value: "string"},
             kind: :InputValueDefinition, loc: %{start: 0},
             name: %{kind: :Name, loc: %{start: 0},
               value: "argument"},
             type: %{kind: :NamedType, loc: %{start: 0},
               name: %{kind: :Name, loc: %{start: 0},
                 value: "String"}}}], kind: :FieldDefinition,
          loc: %{start: 0},
          name: %{kind: :Name, loc: %{start: 0}, value: "four"},
          type: %{kind: :NamedType, loc: %{start: 0},
            name: %{kind: :Name, loc: %{start: 0},
              value: "String"}}}], kind: :InterfaceTypeDefinition,
       loc: %{start: 0},
       name: %{kind: :Name, loc: %{start: 0}, value: "Bar"}},
     %{kind: :UnionTypeDefinition, loc: %{start: 0},
       name: %{kind: :Name, loc: %{start: 0}, value: "Feed"},
       types: [%{kind: :NamedType, loc: %{start: 0},
          name: %{kind: :Name, loc: %{start: 0}, value: "Story"}},
        %{kind: :NamedType, loc: %{start: 0},
          name: %{kind: :Name, loc: %{start: 0}, value: "Article"}},
        %{kind: :NamedType, loc: %{start: 0},
          name: %{kind: :Name, loc: %{start: 0}, value: "Advert"}}]},
     %{kind: :ScalarTypeDefinition, loc: %{start: 0},
       name: %{kind: :Name, loc: %{start: 0}, value: "CustomScalar"}},
     %{kind: :EnumTypeDefinition, loc: %{start: 0},
       name: %{kind: :Name, loc: %{start: 0}, value: "Site"},
       values: ["DESKTOP", "MOBILE"]},
     %{fields: [%{kind: :InputValueDefinition, loc: %{start: 0},
          name: %{kind: :Name, loc: %{start: 0}, value: "key"},
          type: %{kind: :NonNullType, loc: %{start: 0},
            type: %{kind: :NamedType, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0},
                value: "String"}}}},
        %{defaultValue: %{kind: :IntValue, loc: %{start: 0},
            value: 42}, kind: :InputValueDefinition, loc: %{start: 0},
          name: %{kind: :Name, loc: %{start: 0}, value: "answer"},
          type: %{kind: :NamedType, loc: %{start: 0},
            name: %{kind: :Name, loc: %{start: 0}, value: "Int"}}}],
       kind: :InputObjectTypeDefinition, loc: %{start: 0},
       name: %{kind: :Name, loc: %{start: 0}, value: "InputType"}},
     %{definition: %{fields: [%{arguments: [%{kind: :InputValueDefinition,
               loc: %{start: 0},
               name: %{kind: :Name, loc: %{start: 0},
                 value: "argument"},
               type: %{kind: :ListType, loc: %{start: 0},
                 type: %{kind: :NamedType, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "String"}}}}], kind: :FieldDefinition,
            loc: %{start: 0},
            name: %{kind: :Name, loc: %{start: 0}, value: "seven"},
            type: %{kind: :NamedType, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0},
                value: "Type"}}}], kind: :ObjectTypeDefinition,
         loc: %{start: 0},
         name: %{kind: :Name, loc: %{start: 0}, value: "Foo"}},
       kind: :TypeExtensionDefinition, loc: %{start: 0}}],
    kind: :Document, loc: %{start: 0}}
  end
end
