
defmodule GraphQL.Execution.ExecutionContext do

  defstruct [:schema, :fragments, :root_value, :operation, :variable_values, :errors]
  @type t :: %__MODULE__{
    schema: GraphQL.Schema.t,
    fragments: struct,
    root_value: Map,
    operation: Map,
    variable_values: Map,
    errors: list(GraphQL.Error.t)
  }

  @spec new(GraphQL.Schema.t, GraphQL.Document.t, map, map, String.t) :: __MODULE__.t
  def new(schema, document, root_value, variable_values, operation_name) do
    execution_context = Enum.reduce document.definitions, %__MODULE__{
      schema: schema,
      fragments: %{},
      root_value: root_value,
      operation: nil,
      variable_values: variable_values || %{},
      errors: []
    }, fn(definition, context) ->
      case definition do
        %{kind: :OperationDefinition} ->
          cond do
            !operation_name && context.operation ->
              report_error(context, "Must provide operation name if query contains multiple operations.")
            !operation_name || definition.name.value === operation_name ->
              context = %{context | operation: definition}
              %{context | variable_values: GraphQL.Execution.Variables.extract(context) }
            true -> context
          end
        %{kind: :FragmentDefinition} ->
          put_in(context.fragments[definition.name.value], definition)
      end
    end
    if operation_name && !execution_context.operation do
      report_error(execution_context, "Operation `#{operation_name}` not found in query.")
    else
      execution_context
    end
  end

  @spec report_error(__MODULE__.t, String.t) :: __MODULE__.t
  def report_error(context, msg) do
    put_in(context.errors, [%{"message" => msg} | context.errors])
  end
end
