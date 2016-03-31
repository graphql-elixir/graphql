defmodule GraphQL.Type.Int do
  @max_int 2147483647
  @min_int -2147483648

  @type t :: %GraphQL.Type.Int{name: binary, description: binary}
  defstruct name: "Int", description:
    """
    The `Int` scalar type represents non-fractional signed whole numeric
    values. Int can represent values between -(2^53 - 1) and 2^53 - 1 since
    represented in JSON as double-precision floating point numbers specified
    by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).
    """

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

  defimpl String.Chars do
    def to_string(_), do: "Int"
  end
end

defimpl GraphQL.Types, for: GraphQL.Type.Int do
  def parse_value(_, value), do: GraphQL.Type.Int.coerce(value)
  def serialize(_, value), do: GraphQL.Type.Int.coerce(value)
  def parse_literal(_, v), do: v.value
end
