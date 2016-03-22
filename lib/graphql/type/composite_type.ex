
defmodule GraphQL.Type.CompositeType do
  @moduledoc ~S"""
  Provides *get_field* and *get_fields* accessors for composite types.
  This abstacts over the *fields* key being a map or a function that returns a map.
  """
  alias GraphQL.Type.{Object, Union, Interface, Input}

  def has_field?(%Interface{fields: fields}, field_name), do: !!_get_field(fields, field_name)
  def has_field?(%Object{fields: fields}, field_name), do: !!_get_field(fields, field_name)
  def has_field?(%Union{types: types}, field_name), do: !!_get_field(types, field_name)
  def has_field?(%Input{fields: fields}, field_name), do: !!_get_field(fields, field_name)

  def get_fields(%Interface{fields: fields}), do: _get_fields(fields)
  def get_fields(%Object{fields: fields}), do: _get_fields(fields)
  def get_fields(%Union{types: types}), do: _get_fields(types)
  def get_fields(%Input{fields: fields}), do: _get_fields(fields)

  def get_field(%Union{types: types}, field_name), do: _get_field(types, field_name)
  def get_field(%Interface{fields: fields}, field_name), do: _get_field(fields, field_name)
  def get_field(%Object{fields: fields}, field_name), do: _get_field(fields, field_name)
  def get_field(%Input{fields: fields}, field_name), do: _get_field(fields, field_name)

  defp _get_fields(fields) when is_function(fields), do: fields.()
  defp _get_fields(fields) when is_map(fields), do: fields
  defp _get_fields(types) when is_list(types) do
    Enum.reduce(types, %{}, fn(t, acc) -> Map.merge(acc, get_fields(t)) end)
  end

  defp _get_field(fields, field_name) when is_binary(field_name) do
    _get_field(fields, String.to_existing_atom(field_name))
  end
  defp _get_field(fields, field_name) when is_atom(field_name) do
    _get_fields(fields)[field_name]
  end
end
