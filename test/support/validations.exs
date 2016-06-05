
defmodule ValidationsSupport do
  use ExUnit.Case, async: true

  alias GraphQL.Schema
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.List
  alias GraphQL.Type.ID
  alias GraphQL.Type.String
  alias GraphQL.Type.Int
  alias GraphQL.Type.Float
  alias GraphQL.Type.Boolean
  alias GraphQL.Type.Interface
  alias GraphQL.Type.Union
  alias GraphQL.Type.Enum
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.Input

  alias GraphQL.Lang.Parser
  alias GraphQL.Validation.Validator

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
          name: %{ type: %String{} },
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
          name: %{ type: %String{} },
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
      %ObjectType{
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
      %ObjectType{
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
      %ObjectType{
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
      %ObjectType{
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

  defmodule ComplexInput do
    def type do
      %Input{
        fields: %{
          requiredField: %{ type: %NonNull{ofType: %Boolean{}} },
          intField: %{ type: %Int{} },
          stringField: %{ type: %String{} },
          booleanField: %{ type: %Boolean{} },
          stringListField: %{ type: %List{ofType: %String{}} },
        }
      }
    end
  end

  defmodule ComplicatedArgs do
    def type do
      %ObjectType{
        fields: fn() -> %{
          intArgField: %{
            type: %String{},
            args: %{ intArg: %{ type: %Int{} } },
          },
          nonNullIntArgField: %{
            type: %String{},
            args: %{ nonNullIntArg: %{ type: %NonNull{ofType: %Int{}} } },
          },
          stringArgField: %{
            type: %String{},
            args: %{ stringArg: %{ type: %String{} } },
          },
          booleanArgField: %{
            type: %String{},
            args: %{ booleanArg: %{ type: %Boolean{} } },
          },
          enumArgField: %{
            type: %String{},
            args: %{ enumArg: %{ type: FurColor.type } },
          },
          floatArgField: %{
            type: %String{},
            args: %{ floatArg: %{ type: %Float{} } },
          },
          idArgField: %{
            type: %String{},
            args: %{ idArg: %{ type: %ID{} } },
          },
          stringListArgField: %{
            type: %String{},
            args: %{ stringListArg: %{ type: %List{ofType: %String{}} } },
          },
          complexArgField: %{
            type: %String{},
            args: %{ complexArg: %{ type: ComplexInput.type } },
          },
          multipleReqs: %{
            type: %String{},
            args: %{
              req1: %{ type: %NonNull{ofType: %Int{}} },
              req2: %{ type: %NonNull{ofType: %Int{}} },
            },
          },
          multipleOpts: %{
            type: %String{},
            args: %{
              opt1: %{
                type: %Int{},
                defaultValue: 0,
              },
              opt2: %{
                type: %Int{},
                defaultValue: 0,
              },
            },
          },
          multipleOptAndReq: %{
            type: %String{},
            args: %{
              req1: %{ type: %NonNull{ofType: %Int{}} },
              req2: %{ type: %NonNull{ofType: %Int{}} },
              opt1: %{
                type: %Int{},
                defaultValue: 0,
              },
              opt2: %{
                type: %Int{},
                defaultValue: 0,
              }
            }
          }
        } end
      }
    end
  end

  defmodule TestSchema do
    def schema do
      Schema.new(%{
        query: %ObjectType{
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
            complicatedArgs: %{ type: ComplicatedArgs.type },
          } end
        }
      })
    end
  end

  defp validate(schema, query_string, rules) do
    schema = Schema.with_type_cache(schema)
    {:ok, document} = Parser.parse(query_string)
    case Validator.validate_with_rules(schema, document, rules) do
      :ok -> []
      {:error, errors} -> errors
    end
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

  def assert_fails_rule(query_string, rule, expected_errors) do
    assert_invalid(TestSchema.schema, query_string, [ rule ], expected_errors)
  end

  def assert_fails_rule(query_string, rule) do
    assert_invalid(TestSchema.schema, query_string, [ rule ])
  end
end
