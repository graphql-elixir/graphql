defmodule GraphQL.Type.NonNull do
  @type t :: %{ofType: map}
  defstruct ofType: nil
end
