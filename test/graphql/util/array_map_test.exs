
defmodule GraphQL.Util.ArrayMapTest do
  use ExUnit.Case, async: true

  alias GraphQL.Util.ArrayMap

  test "implements Access" do
    version_1 = %ArrayMap{map: %{0 => :zero, 1 => :one, 2 => :two}}
    version_2 = %ArrayMap{map: %{0 => :zero, 1 => :ONE, 2 => :two}}

    version_1_updated = put_in(version_1, [1], :ONE)

    assert version_2 == version_1_updated
  end
end
