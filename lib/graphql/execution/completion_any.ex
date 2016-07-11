
defimpl GraphQL.Execution.Completion, for: Any do
  alias GraphQL.Execution.Types

  def complete_value(return_type, context, _field_asts, _info, result) do
    {context, GraphQL.Types.serialize(Types.unwrap_type(return_type), result)}
  end
end

