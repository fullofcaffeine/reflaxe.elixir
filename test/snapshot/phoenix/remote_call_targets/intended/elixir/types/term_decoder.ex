defmodule TermDecoder do
  def kind(term) do
    if (Kernel.is_nil(term)) do
      {:nil}
    else
      if (Kernel.is_boolean(term)) do
        {:boolean}
      else
        if (Kernel.is_integer(term)) do
          {:integer}
        else
          if (Kernel.is_float(term)) do
            {:float}
          else
            if (Kernel.is_binary(term)) do
              {:binary}
            else
              if (Kernel.is_bitstring(term)) do
                {:bitstring}
              else
                if (Kernel.is_atom(term)) do
                  {:atom}
                else
                  if (Kernel.is_list(term)) do
                    {:list}
                  else
                    if (Kernel.is_map(term)) do
                      {:map}
                    else
                      if (Kernel.is_tuple(term)) do
                        {:tuple}
                      else
                        if (Kernel.is_pid(term)) do
                          {:pid}
                        else
                          if (Kernel.is_port(term)) do
                            {:port}
                          else
                            if (Kernel.is_reference(term)) do
                              {:reference}
                            else
                              if (Kernel.is_function(term)) do
                                {:function}
                              else
                                if (Kernel.is_number(term)), do: {:number}, else: {:unknown}
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  def fetch(map, key) do
    (case (if (Kernel.is_map(map)), do: {:ok, map}, else: {:error, {:expected_type, {:map}, kind(map)}}) do
      {:ok, validated_map} ->
        fetch_result = Map.fetch(validated_map, key)
        if (match?({:ok, _}, fetch_result)), do: {:ok, elem(fetch_result, 1)}, else: {:error, {:missing_key, Kernel.inspect(key)}}
      {:error, error} -> {:error, error}
    end)
  end
  def fetch_atom_key(map, key) do
    fetch(map, key)
  end
end
