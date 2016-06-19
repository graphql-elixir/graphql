
defmodule GraphQL.Execution.ExecutionContext do

  defstruct [:schema, :fragments, :root_value, :operation, :variable_values, :errors, :batch_resolvables]
  @type t :: %__MODULE__{
    schema: GraphQL.Schema.t,
    fragments: struct,
    root_value: Map,
    operation: Map,
    variable_values: Map,
    batch_resolvables: list
  }

  @spec new(GraphQL.Schema.t, GraphQL.Document.t, map, map, String.t) :: __MODULE__.t
  def new(schema, document, root_value, variable_values, operation_name) do
    Enum.reduce document.definitions, %__MODULE__{
      schema: schema,
      fragments: %{},
      root_value: root_value,
      operation: nil,
      variable_values: variable_values || %{},
      batch_resolvables: [],
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
  end

  @spec report_error(__MODULE__.t, String.t) :: __MODULE__.t
  def report_error(context, msg) do
    put_in(context.errors, [%{"message" => msg} | context.errors])
  end

  def add_batch_resolvable(context, batch_resolvable) do
    put_in(context.batch_resolvables, [batch_resolvable | context.batch_resolvables])
  end
end
