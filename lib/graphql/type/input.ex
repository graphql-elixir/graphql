defmodule GraphQL.Type.Input do
  @type t :: %GraphQL.Type.Input{
    name: binary,
    description: binary,
    fields: map
  }

  defstruct name: "Input", description: "", fields: %{}
end
