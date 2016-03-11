
alias GraphQL.Lang.AST.Visitor
alias GraphQL.Lang.AST.InitialisingVisitor

defmodule GraphQL.Lang.AST.TypeInfo do
  @moduledoc ~S"""
  TypeInfo maintains type metadata pertaining to the current node of a query AST,
  and is used by the TypeInfoVistor.
  """

  alias GraphQL.Util.Stack
  alias GraphQL.Type.List
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.Introspection

  @behavior Access
  defstruct schema: nil,
            type_stack: %Stack{},
            parent_type_stack: %Stack{},
            input_type_stack: %Stack{}, 
            field_def_stack: %Stack{},
            directive: nil,
            argument: nil

  @doc """
  Return the top of the type stack, or nil if empty.
  """
  def type(type_info), do: type_info.type_stack |> Stack.peek()

  def named_type(type_info, type) do
    if type === %List{} || type === %NonNull{} do
      named_type(type_info, type.ofType)
    else
      type
    end
  end

  @doc """
  Return the top of the parent type stack, or nil if empty.
  """
  def parent_type(type_info) do
    type_info.parent_type_stack |> Stack.peek() 
  end

  @doc """
  Return the top of the field def stack, or nil if empty.
  """
  def field_def(type_info) do
    type_info.field_def_stack |> Stack.peek()
  end

  def find_field_def(schema, parent_type, field_node) do
    name = field_node.name.value |> String.to_atom()
    cond do
      name == Introspection.meta(:schema)[:name] && schema.query == parent_type ->
        Introspection.meta(:schema)
      name == Introspection.meta(:type)[:name] && schema.query == parent_type ->
        Introspection.meta(:type)
      name == Introspection.meta(:typename)[:name] ->
        Introspection.meta(:typename)
      parent_type.__struct__ == GraphQL.Type.ObjectType || parent_type.__struct__ == GraphQL.Type.Interface ->
        parent_type.fields[name]
      true ->
        nil
    end
  end
end

