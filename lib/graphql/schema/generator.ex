defmodule GraphQL.Schema.Generator do

  # TODO generate comments with the source types

  def generate(base_filename, source_schema) do
    {:ok, ast} = GraphQL.Lang.Parser.parse(source_schema)
    module_name = base_filename |> Path.basename("_schema") |> Macro.camelize
    {:ok, generate_module(module_name, ast)}
  end

  def generate_module(name, ast) do
    """
    defmodule #{name}.Schema do
    #{walk_ast(ast)}
    end
    """
  end

  def walk_ast(doc = %{kind: :Document}) do
    """
      alias GraphQL.Type

    #{doc.definitions |> Enum.map(&walk_ast/1) |> Enum.join("\n")}

      def schema do
        %GraphQL.Schema{
          query: Query.type,
          # mutation: Mutation.type
        }
      end
    """
  end

  def walk_ast(type_def = %{kind: :ObjectTypeDefinition}) do
    """
      defmodule #{type_def.name.value} do
        def type do
          %Type.ObjectType{
            name: "#{type_def.name.value}",
            description: "#{type_def.name.value} description",
            fields: %{
              #{type_def.fields |> Enum.map(&walk_ast/1) |> Enum.join(",\n          ")}
            }#{interfaces(type_def)}
          }
        end
      end
    """
  end

  def walk_ast(field = %{kind: :FieldDefinition, arguments: args}) when is_list(args) and length(args) > 0 do
    """
    #{field.name.value}: %{
                type: #{walk_ast(field.type)},
                args: %{
                  #{args |> Enum.map(&walk_ast/1) |> Enum.join(",\n")}
                }
              }
    """ |> String.strip
  end

  def walk_ast(input = %{kind: :InputValueDefinition}) do
    "#{input.name.value}: %{type: #{walk_ast(input.type)}}"
  end

  def walk_ast(field = %{kind: :FieldDefinition}) do
    "#{field.name.value}: %{type: #{walk_ast(field.type)}}"
  end

  def walk_ast(type = %{kind: :NonNullType}) do
    "%Type.NonNull{ofType: #{walk_ast(type.type)}}"
  end

  def walk_ast(type = %{kind: :ListType}) do
    "%Type.List{ofType: #{walk_ast(type.type)}}"
  end

  def walk_ast(type = %{kind: :NamedType}) do
    if type.name.value in ~w(String Int ID) do
      "%Type.#{type.name.value}{}"
    else
      type.name.value
    end
  end

  def walk_ast(type_def = %{kind: :EnumTypeDefinition}) do
    """
      defmodule #{type_def.name.value} do
        def type do
          Type.Enum.new %{
            name: "#{type_def.name.value}",
            description: "#{type_def.name.value} description",
            values: %{
              #{type_def.values |> Enum.map(fn (v) -> "#{v}: %{value: 0}" end) |> Enum.join(",\n          ")}
            }
          }
        end
      end
    """
  end

  def walk_ast(type_def = %{kind: :InterfaceTypeDefinition}) do
    """
      defmodule #{type_def.name.value} do
        def type do
          Type.Interface.new %{
            name: "#{type_def.name.value}",
            description: "#{type_def.name.value} description",
            fields: %{
              #{type_def.fields |> Enum.map(&walk_ast/1) |> Enum.join(",\n          ")}
            }
          }
        end
      end
    """
  end

  def walk_ast(type_def = %{kind: :UnionTypeDefinition}) do
    """
      defmodule #{type_def.name.value} do
        def type do
          GraphQL.Type.Union.new %{
            name: "#{type_def.name.value}",
            description: "#{type_def.name.value} description",
            types: [#{type_def.types |> Enum.map(&walk_ast/1) |> Enum.join(", ")}]
          }
        end
      end
    """
  end

  def walk_ast(type_def = %{kind: :ScalarTypeDefinition}) do
    """
      defmodule #{type_def.name.value} do
        def type do
          GraphQL.Type.Union.new %{
            name: "#{type_def.name.value}",
            description: "#{type_def.name.value} description",
            types: [#{type_def.types |> Enum.map(&walk_ast/1) |> Enum.join(", ")}]
          }
        end
      end
    """
  end

  def walk_ast(n) do
    "#{n.kind} not handled!!!"
  end

  def interfaces(type_def) do
    if i = Map.get(type_def, :interfaces) do
      ",
        interfaces: [#{Enum.map_join(i, ", ", &(&1.name.value))}]"
    else
      ""
    end
  end
end
