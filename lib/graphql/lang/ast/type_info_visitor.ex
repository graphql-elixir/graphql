
defmodule GraphQL.Lang.AST.TypeInfoVisitor do
  @moduledoc ~S"""
  A Visitor implementation that adds type information to the accumulator, so that subsequent
  visitors can use the information to perform validations.

  NOTE: this file is mostly a straight clone from the graphql-js implementation.
  There were no tests for the graphql-js implementation and there are no tests for this one.
  Like the JS version, this implementation will be tested indirectly by the validator tests.
  """

  alias GraphQL.Type
  alias GraphQL.Util.Stack
  alias GraphQL.Lang.AST.TypeInfo
  alias GraphQL.Lang.AST.Visitor
  alias GraphQL.Schema

  defstruct name: "TypeInfoVisitor"

  defimpl Visitor do

    defmacrop stack_push(stack_name, value) do
      quote do
        old_type_info = var!(accumulator)[:type_info]
        new_type_info = %TypeInfo{old_type_info |
          unquote(stack_name) => Stack.push(old_type_info.unquote(stack_name), unquote(value))}
        var!(accumulator) = put_in(var!(accumulator)[:type_info], new_type_info)
      end
    end

    defmacrop stack_pop(stack_name) do
      quote do
        old_type_info = var!(accumulator)[:type_info]
        new_type_info = %TypeInfo{old_type_info |
          unquote(stack_name) => Stack.pop(old_type_info.unquote(stack_name))}
        var!(accumulator) = put_in(var!(accumulator)[:type_info], new_type_info)
      end
    end

    defmacrop set_directive(directive) do
      quote do
        var!(accumulator) = put_in(
          var!(accumulator),
          var!(accumulator)[:type_info].directive,
          Schema.directive(var!(accumulator)[:type_info].schema, unquote(directive))
        )
      end
    end

    defmacrop set_argument(argument) do
      quote do
        var!(accumulator) = put_in(
          var!(accumulator),
          var!(accumulator)[:type_info].argument,
          Schema.argument(var!(accumulator)[:type_info].schema, unquote(argument))
        )
      end
    end

    def enter(_visitor, node, accumulator) do
      case node.kind do
        :SelectionSet ->
          type = TypeInfo.type(accumulator[:type_info])
          named_type = TypeInfo.named_type(accumulator[:type_info], type)
          if Type.is_composite_type?(named_type) do
            stack_push(:parent_type_stack, named_type)
          else
            stack_push(:parent_type_stack, nil)
          end
        :Field ->
          parent_type = TypeInfo.parent_type(accumulator[:type_info])
          if parent_type do
            field_def = TypeInfo.find_field_def(
              accumulator[:type_info].schema,
              parent_type,
              node
            )
            field_def_type = if field_def, do: field_def.type, else: nil
            stack_push(:field_def_stack, field_def)
            stack_push(:type_stack, field_def_type)
          else
            stack_push(:field_def_stack, nil)
            stack_push(:type_stack, nil)
          end
        :Directive ->
          set_directive(node.name.value)
        :OperationDefinition ->
          type = case node.operation do
            :query -> accumulator[:type_info].schema.query
            :mutation -> accumulator[:type_info].schema.mutation
            # TODO 'subscription' -> schema.subscription
            _ -> raise "node operation #{node.operation} not handled"
          end
          stack_push(:type_stack, type)
        kind when kind in [:InlineFragment, :FragmentDefinition] ->
          output_type = if Map.has_key?(node, :typeCondition) do
            Schema.type_from_ast(node.typeCondition, accumulator[:type_info].schema)
          else
            TypeInfo.type(accumulator[:type_info])
          end
          stack_push(:type_stack, output_type)
        :VariableDefinition ->
          input_type = Schema.type_from_ast(node.type, accumulator[:type_info].schema)
          stack_push(:input_type_stack, input_type)
        :Argument ->
          field_or_directive = TypeInfo.directive(accumulator[:type_info]) ||
                               TypeInfo.field_def(accumulator[:type_info])
          if field_or_directive do
            arg_def = Enum.find(
              field_or_directive.arguments,
              fn(arg) -> arg.name == node.name.value end
            )
            set_argument(arg_def)
            stack_push(:input_type_stack, (if Map.has_key?(arg_def, :type), do: arg_def.type, else: nil))
          else
            set_argument(nil)
            stack_push(:input_type_stack, nil)
          end
        :List ->
          input_type = TypeInfo.input_type(accumulator[:type_info])
          list_type =  TypeInfo.nullable_type(accumulator[:type_info], input_type)
          if list_type === %GraphQL.Type.List{} do
            stack_push(:input_type_stack, list_type.ofType)
          else
            stack_push(:input_type_stack, nil)
          end
        :ObjectField ->
          input_type = TypeInfo.input_type(accumulator[:type_info])
          object_type = TypeInfo.named_type(accumulator[:type_info], input_type)
          if %GraphQL.Type.Object{} = object_type do
            # WTF: can't understand what I'm piping to here.
            input_field = accumulator[:type_info] |> object_type.fields[node.name.value]
            field_type = if input_field, do: input_field.type, else: nil
            stack_push(:input_type_stack, field_type)
          else
            stack_push(:input_type_stack, nil)
          end
        _ ->
          :ignore
      end
      {:continue, accumulator}
    end

    def leave(_visitor, node, accumulator) do
      case node.kind do
        :SelectionSet ->
          stack_pop(:parent_type_stack)
        :Field ->
          stack_pop(:field_def_stack)
          stack_pop(:type_stack)
        :Directive ->
          set_directive(nil)
        kind when kind in [:OperationDefinition, :InlineFragment, :FragmentDefinition] ->
          stack_pop(:type_stack)
        :Argument ->
          set_argument(nil)
        kind when kind in [:List, :ObjectField, :VariableDefinition] ->
          stack_pop(:input_type_stack)
        _ ->
          :ignore
      end
      {:continue, accumulator}
    end
  end
end
