defimpl GraphQL.Execution.Completion, for: Atom do
  alias GraphQL.Execution.Completion
  alias GraphQL.Execution.Types

  def complete_value(return_type, context, field_asts, info, result) do
    Completion.complete_value(Types.unwrap_type(return_type), context, field_asts, info, result)
  end
end

