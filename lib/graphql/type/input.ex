defmodule GraphQL.Type.Input do
  @type t :: %GraphQL.Type.Input{
    name: binary,
    description: binary,
    fields: Map.t | function
  }

  defstruct name: "Input", description: "", fields: %{}
end
