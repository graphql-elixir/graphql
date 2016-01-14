defmodule StarWars.Data do
  def get_character(id) do
    get_human(id) || get_droid(id)
  end

  def get_human(nil), do: nil
  def get_human(id) do
    Map.get(human_data, String.to_atom(id), nil)
  end

  def get_droid(nil), do: nil
  def get_droid(id) do
    Map.get(droid_data, String.to_atom(id), nil)
  end

  def get_friends(character) do
    Map.get(character, :friends)
    |> Enum.map(&(get_character(&1)))
  end

  def get_hero(5), do: luke
  def get_hero(_), do: artoo
  def get_hero, do: artoo

  def luke do
    %{id: "1000",
      name: "Luke Skywalker",
      friends: ["1002", "1003", "2000", "2001"],
      appears_in: [4,5,6],
      home_planet: "Tatooine"}
  end

  def vader do
    %{id: "1001",
      name: "Darth Vader",
      friends: ["1004"],
      appears_in: [4,5,6],
      home_planet: "Tatooine"}
  end

  def han do
    %{id: "1002",
      name: "Han Solo",
      friends: ["1000", "1003", "2001"],
      appears_in: [4,5,6]}
  end

  def leia do
    %{id: "1003",
      name: "Leia Organa",
      friends: ["1000", "1002", "2000", "2001"],
      appears_in: [4,5,6],
      home_planet: "Alderaan"}
  end

  def tarkin do
    %{id: "1004",
      name: "Wilhuff Tarkin",
      friends: ["1001"],
      appears_in: [4]}
  end

  def human_data do
    %{"1000": luke, "1001": vader, "1002": han,
      "1003": leia, "1004": tarkin}
  end

  def threepio do
    %{id: "2000",
      name: "C-3PO",
      friends: ["1000", "1002", "1003", "2001"],
      appears_in: [4,5,6],
      primary_function: "Protocol"}
  end

  def artoo do
    %{id: "2001",
      name: "R2-D2",
      friends: ["1000", "1002", "1003"],
      appears_in: [4,5,6],
      primary_function: "Astromech"}
  end

  def droid_data do
    %{"2000": threepio, "2001": artoo}
  end
end
