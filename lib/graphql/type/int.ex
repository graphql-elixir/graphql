defmodule GraphQL.Type.Int do
  @max_int 2147483647
  @min_int -2147483648

  defstruct name: "Int", description: "Blah blah -(2^53-1) and 2^53 - 1"

  def coerce(false), do: 0
  def coerce(true), do: 1
  def coerce(value) when is_binary(value) do
    case Float.parse(value) do
      :error -> nil
      {v, _} -> coerce(v)
    end
  end
  def coerce(value) do
    if value <= @max_int && value >= @min_int do
      if value < 0 do
        round(Float.ceil(value * 1.0, 0))
      else
        round(Float.floor(value * 1.0, 0))
      end
    else
      nil
    end
  end
end

defimpl GraphQL.Types, for: GraphQL.Type.Int do
  def parse_value(_, value), do: GraphQL.Type.Int.coerce(value)
  def serialize(_, value), do: GraphQL.Type.Int.coerce(value)
end
