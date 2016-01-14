defmodule GraphQL.Type.Introspection do
  alias GraphQL.Type.String
  alias GraphQL.Type.NonNull

  def typename do
    %{
      name: "__typename",
      type: %NonNull{of_type: %String{}},
      description: "The name of the current Object type at runtime.",
      args: [],
      resolve: fn(_, _, %{parent_type: %{name: name}}) -> name end
    }
  end
end
