
defmodule GraphQL.Validation.Rules.FieldsOnCorrectType do

  alias GraphQL.Lang.AST.{Visitor, TypeInfo}
  alias GraphQL.Type.{CompositeType, ObjectType, AbstractType}
  alias GraphQL.Type
  import GraphQL.Validation

  defstruct name: "FieldsOnCorrectType"

  defimpl Visitor do

    @max_type_suggestions 5

    def enter(_visitor, %{kind: :Field} = node, accumulator) do
      schema = accumulator[:type_info].schema
      parent_type = TypeInfo.parent_type(accumulator[:type_info])
      field_def = TypeInfo.find_field_def(schema, parent_type, node)
      if parent_type && !field_def do
        {:continue, report_error(
          accumulator,
          undefined_field_message(schema, node.name.value, parent_type)
        )}
      else
        {:continue, accumulator}
      end
    end

    def enter(_visitor, _node, accumulator), do: {:continue, accumulator}

    def leave(_visitor, _node, accumulator), do: accumulator

    defp sibling_interfaces_including_field(schema, type, field_name) do
      AbstractType.possible_types(type, schema)
      |> Enum.filter(&is_a_graphql_object_type/1)
      |> Enum.flat_map(&to_self_and_interfaces/1)
      |> Enum.reduce(%{}, to_field_usage_counts(field_name))
      |> Enum.filter(&by_at_least_one_usage/1)
      |> Enum.uniq()
      |> Enum.sort_by(&field_usage_count/1)
      |> Enum.map(fn({iface,_}) -> iface end)
    end

    defp field_usage_count({_, count}), do: count

    # TODO is this meant to be a ==?
    defp is_a_graphql_object_type(type), do: %ObjectType{} = type

    defp to_self_and_interfaces(type), do: [type] ++ type.interfaces

    defp to_field_usage_counts(field_name) do
      fn(iface, counts) ->
        incr = if CompositeType.has_field?(iface, field_name), do: 1, else: 0
        Map.merge(counts, %{
          iface.name => Map.get(counts, iface.name, 0) + incr
        })
      end
    end

    defp by_at_least_one_usage({_iface, count}), do: count > 0

    defp implementations_including_field(schema, type, field_name) do
      AbstractType.possible_types(type, schema)
      |> Enum.filter(&CompositeType.get_field(&1, field_name))
      |> Enum.map(&(&1.name))
      |> Enum.sort()
    end

    defp suggest_types(schema, field_name, type) do
      if Type.is_abstract?(type) do
        (sibling_interfaces_including_field(schema, type, field_name)
        ++ implementations_including_field(schema, type, field_name))
        |> Enum.uniq()
      else
        []
      end
    end

    defp undefined_field_message(schema, field_name, type) do
      suggested_types = suggest_types(schema, field_name, type)
      message = "Cannot query field \"#{field_name}\" on type \"#{type.name}\"."
      if length(suggested_types) > 0 do
        suggestions =
          suggested_types
          |> Enum.slice(0, @max_type_suggestions)
          |> Enum.map(&"\"#{&1}\"")
          |> Enum.join(", ")
        "#{message} However, this field exists on #{suggestions}. " <>
        "Perhaps you meant to use an inline fragment?"
      else
        message
      end
    end
  end
end
