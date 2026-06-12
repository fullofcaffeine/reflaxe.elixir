defmodule HttpBaseRuntime do
  def create() do
    
            (fn ->
              ref = make_ref()
              Process.put({:reflaxe_http_base, ref}, %{
                headers: [],
                params: [],
                post_data: nil,
                post_bytes: nil,
                response_bytes: nil,
                failed: false,
                last_error: nil
              })
              ref
            end).()
        
  end
  def reset_response(ref) do
    
            key = {:reflaxe_http_base, ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | response_bytes: nil, failed: false, last_error: nil})
            :ok
        
  end
  def set_header(ref, name, value) do
    update_pair(ref, :headers, name, value, true)
  end
  def add_header(ref, name, value) do
    update_pair(ref, :headers, name, value, false)
  end
  def set_parameter(ref, name, value) do
    update_pair(ref, :params, name, value, true)
  end
  def add_parameter(ref, name, value) do
    update_pair(ref, :params, name, value, false)
  end
  defp update_pair(ref, field, name, value, replace) do
    
            key = {:reflaxe_http_base, ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            pair = {name, value}
            pairs = Map.fetch!(state, field)

            next_pairs =
              if replace do
                {replaced, reversed} =
                  Enum.reduce(pairs, {false, []}, fn {existing_name, existing_value}, {found, acc} ->
                    if existing_name == name and not found do
                      {true, [pair | acc]}
                    else
                      {found, [{existing_name, existing_value} | acc]}
                    end
                  end)

                if replaced, do: Enum.reverse(reversed), else: pairs ++ [pair]
              else
                pairs ++ [pair]
              end

            Process.put(key, Map.put(state, field, next_pairs))
            :ok
        
  end
  def headers(ref) do
    
            Process.get({:reflaxe_http_base, ref}).headers
            |> Enum.map(fn {name, value} -> %{name: name, value: value} end)
        
  end
  def header_pairs(ref) do
    Process.get({:reflaxe_http_base, ref}).headers
  end
  def header_value(ref, name) do
    
            expected = String.downcase(name)
            Process.get({:reflaxe_http_base, ref}).headers
            |> Enum.find_value(fn {header_name, header_value} ->
              if String.downcase(header_name) == expected, do: header_value, else: nil
            end)
        
  end
  def encoded_params(ref) do
    
            Process.get({:reflaxe_http_base, ref}).params
            |> Enum.map_join("&", fn {name, value} ->
              URI.encode(name) <> "=" <> URI.encode(value)
            end)
        
  end
  def set_post_data(ref, data) do
    
            key = {:reflaxe_http_base, ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | post_data: data, post_bytes: nil})
            :ok
        
  end
  def set_post_bytes(ref, data) do
    
            key = {:reflaxe_http_base, ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            post_bytes =
              case data do
                nil -> nil
                bytes -> bytes
              end
            Process.put(key, %{state | post_data: nil, post_bytes: post_bytes})
            :ok
        
  end
  def has_request_body(ref) do
    
            state = Process.get({:reflaxe_http_base, ref})
            not is_nil(state.post_data) or not is_nil(state.post_bytes)
        
  end
  def take_post_data(ref) do
    
            key = {:reflaxe_http_base, ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            value = state.post_data
            Process.put(key, %{state | post_data: nil})
            value
        
  end
  def post_bytes(ref) do
    Process.get({:reflaxe_http_base, ref}).post_bytes
  end
  def set_response_bytes(ref, bytes) do
    
            key = {:reflaxe_http_base, ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | response_bytes: bytes})
            :ok
        
  end
  def response_bytes(ref) do
    Process.get({:reflaxe_http_base, ref}).response_bytes
  end
  def mark_failed(ref, message) do
    
            key = {:reflaxe_http_base, ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | failed: true, last_error: message})
            :ok
        
  end
  def failed(ref) do
    Process.get({:reflaxe_http_base, ref}).failed
  end
  def last_error(ref) do
    Process.get({:reflaxe_http_base, ref}).last_error
  end
  def call_on_data(owner, data) do
    Map.fetch!(owner, :on_data).(data)
  end
  def call_on_bytes(owner, data) do
    Map.fetch!(owner, :on_bytes).(data)
  end
  def call_on_error(owner, message) do
    Map.fetch!(owner, :on_error).(message)
  end
  def call_on_status(owner, status) do
    Map.fetch!(owner, :on_status).(status)
  end
end
