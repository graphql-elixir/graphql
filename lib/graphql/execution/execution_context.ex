
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

    initial_context = %__MODULE__{
      schema: schema,
      fragments: %{},
      root_value: root_value,
      operation: nil,
      variable_values: variable_values || %{},
      errors: []
    }

    document.definitions
    |> Enum.reduce(initial_context, build_definition_handler(operation_name))
    |> validate_operation_exists(operation_name)
  end

  defp build_definition_handler(operation_name) do
    fn(definition, context) -> handle_definition(operation_name, definition, context) end
  end

  defp handle_definition(operation_name, definition = %{kind: :OperationDefinition}, context) do
    multiple_operations_no_operation_name = !operation_name && context.operation
    should_set_operation = !operation_name || definition.name.value === operation_name
    cond do
      multiple_operations_no_operation_name ->
        report_error(context, "Must provide operation name if query contains multiple operations.")
      should_set_operation ->
        context = %{context | operation: definition}
        %{context | variable_values: GraphQL.Execution.Variables.extract(context) }
      true -> context
    end
  end

  defp handle_definition(_, definition = %{kind: :FragmentDefinition}, context) do
    put_in(context.fragments[definition.name.value], definition)
  end

  defp validate_operation_exists(context, nil), do: context
  defp validate_operation_exists(context = %{operation: nil}, operation_name) do
    report_error(context, "Operation `#{operation_name}` not found in query.")
  end
  defp validate_operation_exists(context, _operation_name), do: context

  @spec report_error(__MODULE__.t, String.t) :: __MODULE__.t
  def report_error(context, msg) do
    put_in(context.errors, [%{"message" => msg} | context.errors])
  end
end
