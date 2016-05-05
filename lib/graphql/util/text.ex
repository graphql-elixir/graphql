defmodule GraphQL.Util.Text do
  def normalize(text) do
    text |> String.replace(~r/\n/, " ", global: true) |> String.strip()
  end
end

