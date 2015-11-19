defmodule GraphQL.Object do
  defmacro __using__(opts) do
    quote do
      Module.register_attribute __MODULE__, :fields, accumulate: true, persist: true

      import unquote(__MODULE__), only: [field: 1, field: 2, extend: 1]
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    fields = Module.get_attribute(env.module, :fields)

    quote do
      # generate the struct
      unquote(gen_struct(fields))

      # generate the metadata module
      unquote(gen_metadata(fields))
    end
  end

  defp gen_struct(fields) do
    field_names = Enum.map(fields, fn {name, _} -> name end)

    quote do
      defstruct unquote(field_names)
    end
  end

  defp gen_metadata(fields) do
    quote do
      defmodule Meta do
        def fields do
          unquote(fields)
        end
      end
    end
  end
  
      
  # Public API
  
  defmacro field(name, options \\ []) do
    quote bind_quoted: [name: name, options: options] do
      @fields {name, options}
    end
  end

  defmacro extend(parent_module) do
    quote do
      fields = Module.concat(unquote(parent_module), Meta).fields
      Enum.map(fields, fn {name, options} -> field(name, options) end)
    end
  end

end
