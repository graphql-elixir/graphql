defmodule GraphQL.Type.List do
  alias GraphQL.Execution.Completion

  @type t :: %{ofType: map}
  defstruct ofType: nil

  defimpl String.Chars do
    def to_string(list), do: "[#{list.ofType}]"
  end

  defimpl Completion do
    alias GraphQL.Util.ArrayMap
    alias GraphQL.Execution.Types

    def complete_value(%GraphQL.Type.List{ofType: list_type}, context, field_asts, info, result) do
      {context, value, _} = Enum.reduce result, {context, %ArrayMap{}, 0}, fn(item, {context, acc, count}) ->
        {context, value} = Completion.complete_value(Types.unwrap_type(list_type), context, field_asts, info, item)
        {context, ArrayMap.put(acc, count, value), count + 1}
      end
      {context, value}
    end
  end

  defimpl GraphQL.Types do
    def parse_value(_, nil), do: nil
    def parse_value(_, value) when is_list(value), do: value
    def parse_value(_, value), do: List.wrap(value)
    def serialize(_, value), do: value
    def parse_literal(_, v), do: v.value
  end
end


