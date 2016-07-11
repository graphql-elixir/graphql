defmodule GraphQL.Type.NonNull do
  @type t :: %{ofType: map}
  defstruct ofType: nil

  defimpl String.Chars do
    def to_string(non_null), do: "#{non_null.ofType}!"
  end
end

defimpl GraphQL.Execution.Completion, for: GraphQL.Type.NonNull do
  alias GraphQL.Execution.Completion
  alias GraphQL.Execution.Types

  @spec complete_value(%GraphQL.Type.NonNull{}, ExecutionContext.t, GraphQL.Document.t, any, any) :: {ExecutionContext.t, map}
  def complete_value(%GraphQL.Type.NonNull{ofType: inner_type}, context, field_asts, info, result) do
    Completion.complete_value(Types.unwrap_type(inner_type), context, field_asts, info, result)
  end
end
