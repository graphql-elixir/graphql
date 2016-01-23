Code.require_file "../support/star_wars/data.exs", __DIR__
Code.require_file "../support/star_wars/schema.exs", __DIR__

defmodule GraphQL.StarWars.QueryTest do
  use ExUnit.Case, async: true
  import ExUnit.TestHelpers

  test "correctly identifies R2-D2 as the hero of the Star Wars Saga" do
    query = ~S[ query hero_name_query { hero { name } }]
    assert_execute({query, StarWars.Schema.schema}, %{hero: %{name: "R2-D2"}})
  end

  test "Allows us to query for the ID and friends of R2-D2" do
    query = ~S[
      query hero_and_friends_query {
        hero { id, name, friends { name }}
      }
    ]
    assert_execute {query, StarWars.Schema.schema}, %{
      hero: %{
        friends: [
          %{name: "Luke Skywalker"},
          %{name: "Han Solo"},
          %{name: "Leia Organa"}
        ],
        id: "2001",
        name: "R2-D2"
      }
    }
  end

  test "Allows us to query for the friends of friends of R2-D2" do
    query = ~S[
      query nested_query {
        hero {
          name,
          friends {
            name,
            appears_in,
            friends {
              name
            }
          }
        }
      }
    ]
    assert_execute({query, StarWars.Schema.schema}, %{hero:
      %{name: "R2-D2",
        friends: [
        %{appears_in: ["NEWHOPE", "EMPIRE", "JEDI"],
          friends: [%{name: "Han Solo"}, %{name: "Leia Organa"}, %{name: "C-3PO"}, %{name: "R2-D2"}],
          name: "Luke Skywalker"},
        %{appears_in: ["NEWHOPE", "EMPIRE", "JEDI"],
          friends: [%{name: "Luke Skywalker"}, %{name: "Leia Organa"}, %{name: "R2-D2"}],
          name: "Han Solo"},
        %{appears_in: ["NEWHOPE", "EMPIRE", "JEDI"],
          friends: [%{name: "Luke Skywalker"}, %{name: "Han Solo"}, %{name: "C-3PO"}, %{name: "R2-D2"}],
          name: "Leia Organa"}],
      }})
  end

  test "Allows us to query for Luke Skywalker directly, using his ID" do
    query = ~S[query find_luke { human(id: "1000") { name } } ] # would have been useful for Episode VII
     assert_execute({query, StarWars.Schema.schema}, %{human: %{name: "Luke Skywalker"}})
  end

  test "Allows us to create a generic query, then use it to fetch Luke Skywalker using his ID" do
    query = ~S[query fetch_id($some_id: String!) { human(id: $some_id) { name }}]
    assert_execute({query, StarWars.Schema.schema, %{}, %{"some_id" => "1000"}}, %{human: %{name: "Luke Skywalker"}})
  end

  test "Allows us to create a generic query, then use it to fetch Han Solo using his ID" do
    query = ~S[query fetch_some_id($some_id: String!) { human(id: $some_id) { name }}]
    assert_execute({query, StarWars.Schema.schema, %{}, %{"some_id" => "1002"}}, %{human: %{name: "Han Solo"}})
  end

  @tag :skip # returns %{} instead of nil. Which is right?
  test "Allows us to create a generic query, then pass an invalid ID to get null back" do
    query = ~S[query human_query($id: String!) { human(id: $id) { name }}]
    assert_execute({query, StarWars.Schema.schema, %{}, %{id: "invalid id"}}, %{human: nil})
  end

  test "Allows us to query for Luke, changing his key with an alias" do
    query = ~S[query fetch_luke_aliased { luke: human(id: "1000") { name }}]
    assert_execute({query, StarWars.Schema.schema}, %{luke: %{name: "Luke Skywalker"}})
  end

  test "Allows us to query for both Luke and Leia, using two root fields and an alias" do
    query = ~S[query fetch_luke_and_leia_aliased {
      luke: human(id: "1000") { name },
      leia: human(id: "1003") { name }
    }]
    assert_execute({query, StarWars.Schema.schema}, %{leia: %{name: "Leia Organa"}, luke: %{name: "Luke Skywalker"}})
  end

  test "Allows us to query using duplicated content" do
    query = ~S[
      query duplicate_fields {
        luke: human(id: "1000") { name, home_planet },
        leia: human(id: "1003") { name, home_planet },
      }
    ]
    assert_execute({query, StarWars.Schema.schema}, %{leia: %{home_planet: "Alderaan", name: "Leia Organa"}, luke: %{home_planet: "Tatooine", name: "Luke Skywalker"}})
  end

  test "Allows us to use a fragment to avoid duplicating content" do
    query = ~S[
      query duplicate_fields {
        luke: human(id: "1000") { ...human_fragment },
        leia: human(id: "1003") { ...human_fragment },
      }
      fragment human_fragment on Human {
        name, home_planet
      }
    ]
    assert_execute({query, StarWars.Schema.schema}, %{leia: %{home_planet: "Alderaan", name: "Leia Organa"}, luke: %{home_planet: "Tatooine", name: "Luke Skywalker"}})
  end

  test "Allows us to verify that R2-D2 is a droid" do
    query = ~S[
      query check_type_of_r2d2 {
        hero {
          __typename
          name
        }
      }
    ]
    assert_execute({query, StarWars.Schema.schema}, %{hero: %{name: "R2-D2", "__typename": "Droid"}})
  end

  test "Allows us to verify that Luke is a human" do
    query = ~S[
      query check_type_of_luke {
        hero(episode: EMPIRE) {
          __typename
          name
        }
      }
    ]
    assert_execute({query, StarWars.Schema.schema}, %{hero: %{name: "Luke Skywalker", "__typename": "Human"}})
  end
end
