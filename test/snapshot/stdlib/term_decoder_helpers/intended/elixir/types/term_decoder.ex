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
  def as_string(term) do
    if (Kernel.is_binary(term)), do: {:ok, term}, else: {:error, {:expected_type, {:binary}, kind(term)}}
  end
  def as_int(term) do
    if (Kernel.is_integer(term)), do: {:ok, term}, else: {:error, {:expected_type, {:integer}, kind(term)}}
  end
  def as_bool(term) do
    if (Kernel.is_boolean(term)), do: {:ok, term}, else: {:error, {:expected_type, {:boolean}, kind(term)}}
  end
  def as_float(term) do
    if (Kernel.is_float(term)), do: {:ok, term}, else: {:error, {:expected_type, {:float}, kind(term)}}
  end
  def as_list(term) do
    if (Kernel.is_list(term)), do: {:ok, term}, else: {:error, {:expected_type, {:list}, kind(term)}}
  end
  def as_map(term) do
    if (Kernel.is_map(term)), do: {:ok, term}, else: {:error, {:expected_type, {:map}, kind(term)}}
  end
  def optional(term, decode) do
    if (Kernel.is_nil(term)) do
      {:ok, {:none}}
    else
      ResultTools.map(decode.(term), fn value -> {:some, value} end)
    end
  end
  def fetch(map, key) do
    (case (if (Kernel.is_map(map)), do: {:ok, map}, else: {:error, {:expected_type, {:map}, kind(map)}}) do
      {:ok, validated_map} ->
        fetch_result = Map.fetch(validated_map, key)
        if (match?({{:ok, _}}, fetch_result)), do: {:ok, elem(fetch_result, 1)}, else: {:error, {:missing_key, Kernel.inspect(key)}}
      {:error, error} -> {:error, error}
    end)
  end
  def fetch_string_key(map, key) do
    fetch(map, key)
  end
  def fetch_atom_key(map, key) do
    fetch(map, key)
  end
  def fetch_string_key_as(map, key, decode) do
    ResultTools.flat_map(fetch_string_key(map, key), decode)
  end
  def fetch_atom_key_as(map, key, decode) do
    ResultTools.flat_map(fetch_atom_key(map, key), decode)
  end
  def optional_string_key_as(map, key, decode) do
    (case fetch_string_key(map, key) do
      {:ok, value} ->
        (case decode.(value) do
          {:ok, value} -> {:ok, {:some, value}}
          {:error, value} -> {:error, value}
        end)
      {:error, error} ->
        (case error do
          {:missing_key, _} -> {:ok, {:none}}
          _ -> {:error, error}
        end)
    end)
  end
  def optional_atom_key_as(map, key, decode) do
    (case fetch_atom_key(map, key) do
      {:ok, value} ->
        (case decode.(value) do
          {:ok, value} -> {:ok, {:some, value}}
          {:error, value} -> {:error, value}
        end)
      {:error, error} ->
        (case error do
          {:missing_key, _} -> {:ok, {:none}}
          _ -> {:error, error}
        end)
    end)
  end
  def ok_error(term, decode_ok, decode_error) do
    if (match?({{:ok, _}}, term)) do
      ResultTools.map(decode_ok.(elem(term, 1)), fn value -> {:ok, value} end)
    else
      if (match?({{:error, _}}, term)) do
        ResultTools.map(decode_error.(elem(term, 1)), fn reason -> {:error, reason} end)
      else
        {:error, {:expected_ok_error_tuple, kind(term)}}
      end
    end
  end
end
