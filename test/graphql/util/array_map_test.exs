
defmodule GraphQL.Util.ArrayMapTest do
  use ExUnit.Case, async: true

  alias GraphQL.Util.ArrayMap

  test "implements Access" do
    version_1 = ArrayMap.new(%{0 => :zero, 1 => :one, 2 => :two})
    version_2 = ArrayMap.new(%{0 => :zero, 1 => :ONE, 2 => :two})

    version_1_updated = put_in(version_1, [1], :ONE)

    assert version_2 == version_1_updated
  end

  test "Access works with mix of nested Maps and ArrayMaps" do
    nested =   %{:foo => ArrayMap.new(%{0 => %{:baz => ArrayMap.new(%{0 => %{quux: 123}})}})}
    expected = %{:foo => ArrayMap.new(%{0 => %{:baz => ArrayMap.new(%{0 => %{quux: 456}})}})}

    updated = put_in(nested, [:foo, 0, :baz, 0, :quux], 456)

    assert updated == expected
  end
end
