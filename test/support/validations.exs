
defmodule ValidationsSupport do
  use ExUnit.Case, async: true

  alias GraphQL.Schema
  alias GraphQL.Type.Object
  alias GraphQL.Type.List
  alias GraphQL.Type.ID
  alias GraphQL.Type.String
  alias GraphQL.Type.Int
  alias GraphQL.Type.Boolean
  alias GraphQL.Type.Interface
  alias GraphQL.Type.Union
  alias GraphQL.Type.Enum

  alias GraphQL.Lang.Parser
  alias GraphQL.Lang.AST.CompositeVisitor
  alias GraphQL.Lang.AST.ParallelVisitor
  alias GraphQL.Lang.AST.TypeInfoVisitor
  alias GraphQL.Lang.AST.TypeInfo

  alias GraphQL.Lang.AST.Reducer

  defmodule Being do
    def type do
      %Interface{
        name: "Being",
        fields: %{
          name: %String{},
          args: %{ surname: %{ type: %Boolean{} } }
        }
      }
    end
  end

  defmodule Pet do
    def type do
      %Interface{
        name: "Pet",
        fields: %{
          name: %String{},
          args: %{ surname: %{ type: %Boolean{} } }
        }
      }
    end
  end

  defmodule Canine do
    def type do
      %Interface{
        name: "Canine",
        fields: %{
          name: %String{},
          args: %{ surname: %{ type: %Boolean{} } }
        }
      }
    end
  end

  defmodule DogCommand do
    def type do
      %Enum{
        name: "DogCommand",
        values: %{
          SIT: %{ value: 0 },
          HEEL: %{ value: 1 },
          DOWN: %{ value: 2 }
        }
      }
    end
  end

  defmodule Dog do
    def type do
      %Object{
        name: "Dog",
        fields: fn() -> %{
          name: %{
            type: %String{},
            args: %{ surname: %{ type: %Boolean{} }}
          },
          nickname: %{ type: %String{} },
          barks: %{ type: %Boolean{} },
          barkVolume: %{ type: %Int{} },
          doesKnowCommand: %{
            type: %Boolean{},
            args: %{
              dogCommand: %{ type: DogCommand.type }
            }
          },
          isHouseTrained: %{
            type: %Boolean{},
            args: %{
              atOtherHomes: %{
                type: %Boolean{},
                defaultValue: true
              }
            }
          },
          isAtLocation: %{
            type: %Boolean{},
            args: %{
              x: %{ type: %Int{} },
              y: %{ type: %Int{} }
            }
          }
        } end,
        interfaces: [ Being.type, Pet.type, Canine.type ]
      }
    end
  end

  defmodule FurColor do
    def type do
      %Enum{
        name: "FurColor",
        values: %{
          BROWN: %{ value: 0 },
          BLACK: %{ value: 1 },
          TAN: %{ value: 2 },
          SPOTTED: %{ value: 3 }
        }
      }
    end
  end


  defmodule Cat do
    def type do
      %Object{
        name: "Cat",
        fields: fn() -> %{
          name: %{
            type: %String{},
            args: %{ surname: %{ type: %Boolean{} }}
          },
          nickname: %{ type: %String{} },
          meows: %{ type: %Boolean{} },
          meowVolume: %{ type: %Int{} },
          furColor: %{ type: FurColor.type }
        } end,
        interfaces: [ Being.type, Pet.type ]
      }
    end
  end

  defmodule Intelligent do
    def type do
      %Interface{
        name: "Intelligent",
        fields: %{
          iq: %{ type: %Int{} }
        }
      }
    end
  end

  defmodule CatOrDog do
    def type do
      %Union{
        name: "CatOrDog",
        types: [ Dog.type, Cat.type ]
      }
    end
  end

  defmodule Human do
    def type do
      %Object{
        name: "Human",
        interfaces: [ Being.type, Intelligent.type ],
        fields: fn() -> %{
          name: %{
            type: %String{},
            args: %{ surname: %{ type: %Boolean{} }}
          },
          pets: %{ type: %List{ ofType: Pet.type } },
          relatives: %{ type: %List{ ofType: Human.type } },
          iq: %{ type: %Int{} },
        } end
      }
    end
  end

  defmodule Alien do
    def type do
      %Object{
        name: "Alien",
        interfaces: [ Being.type, Intelligent.type ],
        fields: %{
          name: %{
            type: %String{},
            args: %{ surname: %{ type: %Boolean{} } }
          },
          numEyes: %{ type: %Int{} },
          iq: %{ type: %Int{} }
        }
      }
    end
  end

  defmodule HumanOrAlien do
    def type do
      %Union{
        name: "HumanOrAlien",
        types: [ Human.type, Alien.type ]
      }
    end
  end

  defmodule DogOrHuman do
    def type do
      %Union{
        name: "DogOrHuman",
        types: [ Human.type, Dog.type ]
      }
    end
  end


       
  defmodule TestSchema do
    def schema do
      %Schema{
        query: %Object{
          name: "QueryRoot",
          fields: fn() -> %{
            human: %{
              args: %{ id: %{ type: %ID{} } },
              type: Human.type
            },
            alien: %{ type: Alien.type },
            dog: %{ type: Dog.type },
            cat: %{ type: Cat.type },
            pet: %{ type: Pet.type },
            catOrDog: %{ type: CatOrDog.type },
            dogOrHuman: %{ type: DogOrHuman.type },
            humanOrAlien: %{ type: HumanOrAlien.type },
            #complicatedArgs: %{ type: ComplicatedArgs.type },
          } end
        }
      }
    end
  end


  defp validate(schema, query_string, rules) do
    {:ok, ast} = Parser.parse(query_string)
    validation_pipeline = CompositeVisitor.compose([
      %TypeInfoVisitor{},
      %ParallelVisitor{visitors: rules}
    ])
    result = Reducer.reduce(ast, validation_pipeline, %{
      type_info: %TypeInfo{schema: schema},
      validation_errors: []
    })
    result[:validation_errors]
  end

  def assert_valid(schema, query_string, rules) do
    errors = validate(schema, query_string, rules)
    assert errors == [] 
  end

  def assert_invalid(schema, query_string, rules, expected_errors) do
    errors = validate(schema, query_string, rules)
    assert errors == expected_errors
  end

  def assert_invalid(schema, query_string, rules) do
    errors = validate(schema, query_string, rules)
    assert length(errors) > 0
  end

  def assert_passes_rule(query_string, rule) do
    assert_valid(TestSchema.schema, query_string, [ rule ])
  end

  def assert_fails_rule(query_string, rule, errors) do
    assert_invalid(TestSchema.schema, query_string, [ rule ], errors)
  end

  def assert_fails_rule(query_string, rule) do
    assert_invalid(TestSchema.schema, query_string, [ rule ])
  end
end
