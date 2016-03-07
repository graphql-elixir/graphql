defmodule GraphQL.Type.Enum do
  @type t :: %GraphQL.Type.Enum{
    name: binary,
    description: binary,
    values: %{binary => GraphQL.Type.EnumValue.t}
  }
  defstruct name: "", values: %{}, description: ""

  def new(map) do
    map = %{map | values: define_values(map.values)}
    struct(GraphQL.Type.Enum, map)
  end

  def values(map) do
    Enum.reduce(map.values, %{}, fn(%{name: name, value: value}, acc) ->
      Map.put(acc, name, value)
    end)
  end

  defp define_values(values) do
    Enum.map(values, fn {name, v} ->
      val = Map.get(v, :value, name)
      desc = Map.get(v, :description, "")
      %GraphQL.Type.EnumValue{name: name, value: val, description: desc}
    end)
  end
end

defimpl GraphQL.Types, for: GraphQL.Type.Enum do
  def parse_value(struct, value) do
    GraphQL.Type.Enum.values(struct) |> Map.get(String.to_atom(value))
  end

  def parse_literal(struct, value) do
    GraphQL.Type.Enum.values(struct) |> Map.get(String.to_atom(value.value))
  end

  def serialize(struct, wanted) do
    values = GraphQL.Type.Enum.values(struct)
    case Enum.find(values, fn({_, v}) -> v == wanted end) do
      nil -> nil
      {name, _} -> to_string(name)
    end
  end
end
