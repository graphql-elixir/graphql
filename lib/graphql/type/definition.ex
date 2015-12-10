defmodule GraphQL.ObjectType do
  defstruct name: "RootQueryType", description: "", fields: %{}
end

defmodule GraphQL.List do
  defstruct of_type: nil
end
