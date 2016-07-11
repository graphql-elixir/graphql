
defprotocol GraphQL.Execution.Completion do
  @fallback_to_any true

  @spec complete_value(any, ExecutionContext.t, GraphQL.Document.t, map, map) :: {ExecutionContext.t, any}
  def complete_value(type, context, field_asts, info, result)
end

