defmodule GraphQL.Execution.Executor do
  alias GraphQL.Schema
  alias GraphQL.Execution.ExecutionContext
  alias GraphQL.Lang.AST.Nodes
  alias GraphQL.Util.ArrayMap

  alias GraphQL.Execution.Selection

  @type result_data :: {:ok, Map}

  @doc """
  Execute a query against a schema.

      # iex> Executor.execute(schema, "{ hello }")
      # {:ok, %{hello: world}}
  """
  @spec execute(GraphQL.Schema.t, GraphQL.Document.t, list) :: result_data | {:error, %{errors: list}}
  def execute(schema, document, opts \\ []) do
    schema          = Schema.with_type_cache(schema)
    {root_value, variable_values, operation_name} = expand_options(opts)
    context = ExecutionContext.new(schema, document, root_value, variable_values, operation_name)
    case context.errors do
      [] -> execute_operation(context, context.operation, root_value)
      _  -> {:error, %{errors: Enum.dedup(context.errors)}}
    end
  end

  defp expand_options(opts) do
    {Keyword.get(opts, :root_value, %{}),
     Keyword.get(opts, :variable_values, %{}),
     Keyword.get(opts, :operation_name, nil)}
  end

  @spec execute_operation(ExecutionContext.t, Nodes.operation_node, map) :: result_data | {:error, String.t}
  defp execute_operation(context, operation, root_value) do
    type = Schema.operation_root_type(context.schema, operation)
    {context, %{fields: fields}} = Selection.collect_selections(context, type, operation.selectionSet)
    case operation.operation do
      :query        ->
        {context, result} = Selection.execute_fields(context, type, root_value, fields)
        {:ok, ArrayMap.expand_result(result), context.errors}
      :mutation     ->
        {context, result} = Selection.execute_fields_serially(context, type, root_value, fields)
        {:ok, ArrayMap.expand_result(result), context.errors}
      :subscription ->
        {:error, "Subscriptions not currently supported"}
      _             ->
        {:error, "Can only execute queries, mutations and subscriptions"}
    end
  end
end
