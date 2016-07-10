
# ArrayMap is used for representing lists in intermediate results.
# This means the entire intermediate Executor result representation can
# be manipulated with the Access protocol which will allow for patching
# the entire structure in an ad-hoc manner. This is key to implementing
# deferred resolvers.
defmodule GraphQL.Util.ArrayMap do

  @behaviour Access

  defstruct map: %{}

  def new(map) do
    if !Enum.all?(Map.keys(map), fn(key) -> is_integer(key) end) do
      raise "all key must be integers!"
    end
    %__MODULE__{map: map}
  end

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
    %__MODULE__{map: map}
  end

  def pop(array_map, key) do
    {value, map} = Access.get(array_map.map, key)
    {value, %__MODULE__{map: map}}
  end

  # Converts an intermediate executor result that contains ArrayMaps into one
  # where the array maps are converted into lists.
  def expand_result(result) when is_list(result) do
    Enum.map(result, &expand_result/1)
  end
  def expand_result(%__MODULE__{} = result) do
    Enum.reduce(Enum.sort(Map.keys(result.map)), [], fn(index, acc) ->
      [expand_result(Map.get(result.map, index))] ++ acc
    end) |> Enum.reverse
  end
  def expand_result(result) when is_map(result) do
    Enum.reduce(result, %{}, fn({k, v}, acc) ->
      Map.put(acc, expand_result(k), expand_result(v))
    end)
  end
  def expand_result(result), do: result

end
