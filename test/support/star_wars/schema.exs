defmodule StarWars.Schema do
  import StarWars.Data

  def episode_enum do
    %{
      name: "Episode",
      description: "One of the films in the Star Wars Trilogy",
      values: %{
        NEWHOPE: %{value: 4, description: "Released in 1977"},
        EMPIRE: %{value: 5, description: "Released in 1980"},
        JEDI: %{value: 6, description: "Released in 1983"}
      }
    } |>  GraphQL.Type.Enum.new
  end

  def character_interface do
    %{
      name: "Character",
      description: "A character in the Star Wars Trilogy",
      fields: quote do %{
        id: %{ type: "String" },
        name: %{ type: "String" },
        friends: %{ type: %GraphQL.List{of_type: StarWars.Schema.character_interface} },
        appears_in: %{ type: %GraphQL.List{of_type: StarWars.Schema.episode_enum} }
      } end,
      resolver: fn(x) ->
        if StarWars.Data.get_human(x.id), do: StarWars.Schema.human_type, else: StarWars.Schema.droid_type
      end
    } |> GraphQL.Type.Interface.new
  end

  def human_type do
    %GraphQL.ObjectType{
      name: "Human",
      description: "A humanoid creature in the Star Wars universe",
      fields: %{
        id: %{ type: "String" },
        name: %{ type: "String" },
        friends: %{
          type: %GraphQL.List{of_type: character_interface},
          resolve: fn(item, _, _) -> StarWars.Data.get_friends(item) end
        },
        appears_in: %{ type: %GraphQL.List{of_type: episode_enum} },
        home_planet: %{type: "String" }
      },
      interfaces: [ StarWars.Schema.character_interface ]
    }
  end

  def droid_type do
    %GraphQL.ObjectType{
      name: "Droid",
      description: "A mechanical creature in the Star Wars universe",
      fields: %{
        id: %{ type: "String" },
        name: %{ type: "String" },
        friends: %{
          type: %GraphQL.List{of_type: character_interface},
          resolve: fn(item, _, _) -> StarWars.Data.get_friends(item) end
        },
        appears_in: %{ type: %GraphQL.List{of_type: episode_enum} },
        primary_function: %{type: "String" }
      },
      interfaces: [ character_interface ]
    }
  end

  def query do
    %GraphQL.ObjectType{
      name: "Query",
      fields: %{
        hero: %{
          type: character_interface,
          args: %{
            episode: %{ type: episode_enum, description: "If omitted, returns the hero of the whole saga. If provided, returns the hero of that particular episode" }
          },
          resolve: fn(o, args, rest) ->
            StarWars.Data.get_hero(Dict.get(args, :episode, nil))
          end
        },
        human: %{
          type: human_type,
          args: %{
            id: %{ type: "String" }
          },
          resolve: fn(_, args, _) -> StarWars.Data.get_human(args.id) end
        },
        droid: %{
          type: droid_type,
          args: %{
            id: %{ type: "String" }
          },
          resolve: fn(_, args, _) -> StarWars.Data.get_droid(args.id) end
        },
      }
    }
  end

  def schema do
    %GraphQL.Schema{ query: query }
  end
end
