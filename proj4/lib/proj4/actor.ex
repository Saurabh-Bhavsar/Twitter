defmodule Actor do
  def init(state) do
    role = state |> Enum.at(0)

    cond do
      role == "write" ->
        nil
    end
  end
end
