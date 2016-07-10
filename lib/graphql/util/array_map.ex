
# ArrayMap is used for representing lists in intermediate results.
# This means the entire intermediate Executor result representation can
# be manipulated with the Access protocol which will allow for patching
# the entire structure in an ad-hoc manner. This is key to implementing
# deferred resolvers.
defmodule GraphQL.Util.ArrayMap do

  @behaviour Access

  defstruct map: %{}

  def put(array_map, index, value) when is_integer(index) do
    %__MODULE__{ map: Map.put(array_map.map, index, value) }
  end

  # Access behaviour
  def fetch(array_map, key) do
    case Access.fetch(array_map.map, key) do
      {:ok, value} -> %__MODULE__{map: value}
      :error -> :error
    end
  end

  def get_and_update(array_map, key, list) do
    {value, map} = Access.get_and_update(array_map.map, key, list)
    {value, %__MODULE__{map: map}}
  end

  def get(array_map, key, value) do
    map = Access.get(array_map.map, key, value)
    %__MODULE__{map: value}
  end

  def pop(array_map, key) do
    {value, map} = Access.get(array_map.map, key)
    {value, %__MODULE__{map: map}}
  end
end
