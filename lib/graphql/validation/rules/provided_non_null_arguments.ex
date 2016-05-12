
defmodule GraphQL.Validation.Rules.ProvidedNonNullArguments do

  alias GraphQL.Lang.AST.{Visitor, TypeInfo}
  alias GraphQL.Type
  import GraphQL.Validation

  defstruct name: "ProvidedNonNullArguments"

  defimpl Visitor do

    def enter(_visitor, _node, accumulator) do
      {:continue, accumulator}
    end

    def leave(_visitor, %{kind: :Field} = node, accumulator) do
      field_arguments = case TypeInfo.field_def(accumulator[:type_info]) do
        %{args: arguments} -> Map.to_list(arguments)
        _ -> []
      end
      report_errors(accumulator, field_arguments, node, make_name_to_arg_map(node))
    end

    # TODO: arg check directives once we have implemented directive support
    #def leave(_visitor, %{kind: :Directive} = node, accumulator) do
    #  directive_arguments = case TypeInfo.directive(accumulator[:type_info]) do
    #    %{args: arguments} -> Map.to_list(arguments)
    #    _ -> []
    #  end
    #  {:continue, report_errors(accumulator, directive_arguments, node, make_name_to_arg_map(node))}
    #end

    def leave(_visitor, _, accumulator), do: accumulator

    defp arguments_from_ast_node(%{arguments: arguments}), do: arguments
    defp arguments_from_ast_node(_), do: []

    defp report_errors(accumulator, [], _node, _name_to_arg_map), do: accumulator
    defp report_errors(accumulator, [name_and_arg|remaining_args], node, name_to_arg_map) do
      { arg_name, arg } = name_and_arg
      arg_node = name_to_arg_map[Atom.to_string(arg_name)]
      is_missing = !arg_node

      case {is_missing, arg.type} do
        {true, %Type.NonNull{}} ->
          report_error(
            accumulator,
            missing_field_arg_message(node.name.value, arg_name, arg.type)
          )
        _ -> accumulator
      end |> report_errors(remaining_args, node, name_to_arg_map)
    end

    defp missing_field_arg_message(field_name, arg_name, arg_type) do
      "Field \"#{field_name}\" argument \"#{arg_name}\" of type \"#{arg_type}\" is required but not provided."
    end

    defp make_name_to_arg_map(node) do
      Enum.reduce(arguments_from_ast_node(node), %{}, fn(arg,map) ->
        Map.merge(%{ arg.name.value => arg}, map)
      end)
    end
  end
end
