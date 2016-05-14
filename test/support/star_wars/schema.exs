defmodule StarWars.Schema do

  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.List
  alias GraphQL.Type.Interface
  alias GraphQL.Type.String
  alias GraphQL.Type.NonNull

  alias StarWars.Schema.Episode
  alias StarWars.Schema.Character
  alias StarWars.Schema.Droid
  alias StarWars.Schema.Human

  # GraphQL:
  #
  # enum Episode { NEWHOPE, EMPIRE, JEDI }
  #
  defmodule Episode do
    def type do
      GraphQL.Type.Enum.new %{
        name: "Episode",
        description: "One of the films in the Star Wars Trilogy",
        values: %{
          NEWHOPE: %{value: 4, description: "Released in 1977"},
          EMPIRE: %{value: 5, description: "Released in 1980"},
          JEDI: %{value: 6, description: "Released in 1983"}
        }
      }
    end
  end

  defmodule Character do
    def type do
      Interface.new %{
        name: "Character",
        description: "A character in the Star Wars Trilogy",
        fields: %{
          id: %{type: %NonNull{ofType: %String{}}},
          name: %{type: %String{}},
          friends: %{type: %List{ofType: Character}},
          appears_in: %{type: %List{ofType: Episode}}
        },
        resolver: fn(x) ->
          if StarWars.Data.get_human(x.id), do: Human, else: Droid
        end
      }
    end
  end

  defmodule Human do
    def type do
      %ObjectType{
        name: "Human",
        description: "A humanoid creature in the Star Wars universe",
        fields: %{
          id: %{type: %NonNull{ofType: %String{}}},
          name: %{type: %String{}},
          friends: %{
            type: %List{ofType: Character},
            resolve: fn(item, _, _, _) -> StarWars.Data.get_friends(item) end
          },
          appears_in: %{type: %List{ofType: Episode}},
          home_planet: %{type: %String{}}
        },
        interfaces: [Character]
      }
    end
  end

  defmodule Droid do
    def type do
      %ObjectType{
        name: "Droid",
        description: "A mechanical creature in the Star Wars universe",
        fields: %{
          id: %{type: %NonNull{ofType: %String{}}},
          name: %{type: %String{}},
          friends: %{
            type: %List{ofType: Character},
            resolve: fn(item, _, _, _) -> StarWars.Data.get_friends(item) end
          },
          appears_in: %{type: %List{ofType: Episode}},
          primary_function: %{type: %String{}}
        },
        interfaces: [Character]
      }
    end
  end

  def query do
    %ObjectType{
      name: "Query",
      fields: %{
        hero: %{
          type: Character,
          args: %{
            # TODO this should be a type InputObject
            episode: %{
              type: Episode,
              description: "If omitted, returns the hero of the whole saga. If provided, returns the hero of that particular episode"
            }
          },
          resolve: fn(_, args, _, _) ->
            StarWars.Data.get_hero(Map.get(args, :episode))
          end
        },
        human: %{
          type: Human,
          args: %{
            id: %{type: %NonNull{ofType: %String{}}, description: "id of the human"}
          },
          resolve: fn(_, args, _, _) -> StarWars.Data.get_human(args.id) end
        },
        droid: %{
          type: Droid,
          args: %{
            id: %{type: %NonNull{ofType: %String{}}, description: "id of the droid"}
          },
          resolve: fn(_, args, _, _) -> StarWars.Data.get_droid(args.id) end
        }
      }
    }
  end

  def schema do
    GraphQL.Schema.new(%{query: query})
  end
end
