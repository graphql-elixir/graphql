defmodule GraphQL.Object do

  defmacro __using__(_options) do
    quote do
      Module.register_attribute __MODULE__, :fields, accumulate: true, persist: false

      import unquote(__MODULE__), only: [field: 1, field: 2]
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    fields = Module.get_attribute(env.module, :fields)

    # generate the structure fields
    gen_struct(fields)
  end

  def gen_struct(fields) do
    field_names = Enum.map(fields, fn {name, _} -> name end)

    quote do
      defstruct unquote(field_names)
    end
  end
  
  # Public API
  
  defmacro field(name, options \\ []) do
    quote bind_quoted: [name: name, options: options] do
      @fields {name, options}
    end
  end
end
