
defmodule GraphQL.Type.CompositeType do
  @moduledoc ~S"""
  Provides *get_field* and *get_fields* accessors for composite types.
  This abstacts over the *fields* key being a map or a function that returns a map.
  """
  alias GraphQL.Type.{ObjectType, Interface, Input}

  def has_field?(%Interface{fields: fields}, field_name), do: !!do_get_field(fields, field_name)
  def has_field?(%ObjectType{fields: fields}, field_name), do: !!do_get_field(fields, field_name)
  def has_field?(%Input{fields: fields}, field_name), do: !!do_get_field(fields, field_name)

  def get_fields(%Interface{fields: fields}), do: do_get_fields(fields)
  def get_fields(%ObjectType{fields: fields}), do: do_get_fields(fields)
  def get_fields(%Input{fields: fields}), do: do_get_fields(fields)

  def get_field(%Interface{fields: fields}, field_name), do: do_get_field(fields, field_name)
  def get_field(%ObjectType{fields: fields}, field_name), do: do_get_field(fields, field_name)
  def get_field(%Input{fields: fields}, field_name), do: do_get_field(fields, field_name)

  defp do_get_field(fields, field_name) when is_binary(field_name) do
    try do
      do_get_fields(fields)[String.to_existing_atom(field_name)]
    rescue
      # Handle the error when String.to_existing_atom/1 fails.
      ArgumentError -> nil
    end
  end
  defp do_get_field(fields, field_name) when is_atom(field_name) do
    do_get_fields(fields)[field_name]
  end

  defp do_get_fields(fields) when is_function(fields), do: fields.()
  defp do_get_fields(fields) when is_map(fields), do: fields
end
