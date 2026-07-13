defmodule HandwrittenCorpus.AbstractionLab.ProcessBoundary do
  def current_process_id, do: self()
  def current_node_name, do: current_process_id() |> node() |> to_string()

  def send_if_pid(destination, message) when is_pid(destination) do
    send(destination, message)
    true
  end

  def send_if_pid(_destination, _message), do: false
  def send_to_self(message), do: send(self(), message)

  def term_type(term) do
    cond do
      is_nil(term) -> "nil"
      is_boolean(term) -> "boolean"
      is_atom(term) -> "atom"
      is_binary(term) -> "binary"
      is_float(term) -> "float"
      is_function(term) -> "function"
      is_integer(term) -> "integer"
      is_list(term) -> "list"
      is_map(term) -> "map"
      is_pid(term) -> "pid"
      is_port(term) -> "port"
      is_reference(term) -> "reference"
      is_tuple(term) -> "tuple"
      true -> "unknown"
    end
  end
end
