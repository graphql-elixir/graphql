defmodule GraphQL.Type.NonNull do
  @type t :: %{ofType: map}
  defstruct ofType: nil

  defimpl String.Chars do
    def to_string(non_null), do: "#{non_null.ofType}!"
  end
end

