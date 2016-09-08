
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

    def stack_push(accumulator, stack_name, value) do
      old_type_info = accumulator[:type_info]
      stack = Stack.push(Map.get(old_type_info, stack_name), value)
      new_type_info = Map.merge(old_type_info, %{stack_name => stack})
      put_in(accumulator[:type_info], new_type_info)
    end

    def stack_pop(accumulator, stack_name) do
      old_type_info = accumulator[:type_info]
      stack = Stack.pop(Map.get(old_type_info, stack_name))
      new_type_info = Map.merge(old_type_info, %{stack_name => stack})
      put_in(accumulator[:type_info], new_type_info)
    end

    def set_directive(accumulator, directive) do
      put_in(
        accumulator[:type_info],
        %TypeInfo{accumulator[:type_info] | directive: directive}
      )
    end

    def set_argument(accumulator, argument) do
      put_in(
        accumulator[:type_info],
        %TypeInfo{accumulator[:type_info] | argument: argument}
      )
    end

    def enter(_visitor, node, accumulator) do
      accumulator = case node.kind do
        :SelectionSet ->
          type = TypeInfo.type(accumulator[:type_info])
          named_type = TypeInfo.named_type(type)
          if Type.is_composite_type?(named_type) do
            stack_push(accumulator, :parent_type_stack, named_type)
          else
            stack_push(accumulator, :parent_type_stack, nil)
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
            accumulator = stack_push(accumulator, :field_def_stack, field_def)
            stack_push(accumulator, :type_stack, field_def_type)
          else
            accumulator = stack_push(accumulator, :field_def_stack, nil)
            stack_push(accumulator, :type_stack, nil)
          end
        :Directive ->
          # add this once we add directive validations
          # see ref impl: src/validation/rules/KnownDirectives.js
          #
          # TODO: once we implement directive support in the schema,
          # get the directive definition from the schema by name and
          #this._directive = schema.getDirective(node.name.value); // JS example
          # and set it like this
          #set_directive(directive_def)
          set_directive(accumulator, nil)
        :OperationDefinition ->
          type = case node.operation do
            :query -> accumulator[:type_info].schema.query
            :mutation -> accumulator[:type_info].schema.mutation
            _ -> raise "node operation #{node.operation} not handled"
          end
          stack_push(accumulator, :type_stack, type)
        kind when kind in [:InlineFragment, :FragmentDefinition] ->
          output_type = if Map.has_key?(node, :typeCondition) do
            Schema.type_from_ast(node.typeCondition, accumulator[:type_info].schema)
          else
            TypeInfo.type(accumulator[:type_info])
          end
          stack_push(accumulator, :type_stack, output_type)
        :VariableDefinition ->
          input_type = Schema.type_from_ast(node.type, accumulator[:type_info].schema)
          stack_push(accumulator, :input_type_stack, input_type)
        :Argument ->
          field_or_directive = TypeInfo.directive(accumulator[:type_info]) ||
                               TypeInfo.field_def(accumulator[:type_info])
          if field_or_directive do
            arg_def = Enum.find(
              Map.get(field_or_directive, :arguments, %{}),
              fn(arg) -> arg == node.name.value end
            )
            accumulator = set_argument(accumulator, arg_def)
            stack_push(accumulator, :input_type_stack, (if arg_def && Map.has_key?(arg_def, :type), do: arg_def.type, else: nil))
          else
            accumulator = set_argument(accumulator, nil)
            stack_push(accumulator, :input_type_stack, nil)
          end
        :List ->
          input_type = TypeInfo.input_type(accumulator[:type_info])
          list_type = TypeInfo.named_type(input_type)
          if %Type.List{} === list_type  do
            stack_push(accumulator, :input_type_stack, list_type.ofType)
          else
            stack_push(accumulator, :input_type_stack, nil)
          end
        :ObjectField ->
          input_type = TypeInfo.input_type(accumulator[:type_info])
          object_type = TypeInfo.named_type(input_type)
          if %Type.Input{} === object_type do
            input_field = TypeInfo.find_field_def(
              accumulator[:type_info].schema,
              object_type,
              node
            )
            field_type = if input_field, do: input_field.type, else: nil
            stack_push(accumulator, :input_type_stack, field_type)
          else
            stack_push(accumulator, :input_type_stack, nil)
          end
        _ ->
          accumulator
      end
      {:continue, accumulator}
    end

    def leave(_visitor, node, accumulator) do
      case node.kind do
        :SelectionSet ->
          stack_pop(accumulator, :parent_type_stack)
        :Field ->
          accumulator = stack_pop(accumulator, :field_def_stack)
          stack_pop(accumulator, :type_stack)
        :Directive ->
          set_directive(accumulator, nil)
        kind when kind in [:OperationDefinition, :InlineFragment, :FragmentDefinition] ->
          stack_pop(accumulator, :type_stack)
        :Argument ->
          set_argument(accumulator, nil)
        kind when kind in [:List, :ObjectField, :VariableDefinition] ->
          stack_pop(accumulator, :input_type_stack)
        _ ->
          accumulator
      end
    end
  end
end
