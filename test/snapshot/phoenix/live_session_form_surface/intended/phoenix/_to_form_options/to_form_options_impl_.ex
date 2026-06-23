defmodule ToFormOptions_Impl_ do
  def build(as, id, errors, action, method, multipart) do

              [
                as: if(Kernel.is_nil(as), do: nil, else: String.to_atom(as)),
                id: id,
                errors: errors,
                action: if(Kernel.is_nil(action), do: nil, else: String.to_atom(action)),
                method: method,
                multipart: multipart
              ]
              |> Enum.filter(fn {_, value} -> value != nil end)

  end
end
