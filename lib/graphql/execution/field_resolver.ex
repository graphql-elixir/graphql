
defmodule GraphQL.Execution.FieldResolver do

  alias GraphQL.Execution.Arguments
  alias GraphQL.Execution.Resolvable
  alias GraphQL.Execution.ExecutionContext
  alias GraphQL.Execution.Completion
  alias GraphQL.Execution.Types
  alias GraphQL.Type.CompositeType

  def resolve_field(context, parent_type, source, field_asts) do
    field_ast = hd(field_asts)
    field_name = String.to_existing_atom(field_ast.name.value)

    if field_def = field_definition(parent_type, field_name) do
      return_type = field_def.type

      args = Arguments.argument_values(
        Map.get(field_def, :args, %{}),
        Map.get(field_ast, :arguments, %{}),
        context.variable_values
      )

      info = %{
        field_name: field_name,
        field_asts: field_asts,
        return_type: return_type,
        parent_type: parent_type,
        schema: context.schema,
        fragments: context.fragments,
        root_value: context.root_value,
        operation: context.operation,
        variable_values: context.variable_values
      }

      case resolve(field_def, source, args, info) do
        {:ok, nil} ->
          {context, nil}
        {:ok, result} ->
          Completion.complete_value(return_type, context, field_asts, info, result)
        {:error, message} ->
          {ExecutionContext.report_error(context, message), nil}
      end
    else
      {context, :undefined}
    end
  end

  defp resolve(field_def, source, args, info) do
    Resolvable.resolve(
      Map.get(field_def, :resolve),
      Types.unwrap_type(source),
      args,
      info
    )
  end

  defp field_definition(parent_type, field_name) do
    case field_name do
      :__typename -> GraphQL.Type.Introspection.meta(:typename)
      :__schema -> GraphQL.Type.Introspection.meta(:schema)
      :__type -> GraphQL.Type.Introspection.meta(:type)
      _ -> CompositeType.get_field(parent_type, field_name)
    end
  end
end


