defmodule AbstractionLab.ProcessBoundary do
  def current_process_id() do
    Kernel.self()
  end
  def current_node_name() do
    Kernel.to_string(Kernel.node(current_process_id()))
  end
  def send_if_pid(destination, message) do
    if (not Kernel.is_pid(destination)) do
      false
    else
      _ = Kernel.send(destination, message)
      true
    end
  end
  def send_to_self(message) do
    Kernel.send(current_process_id(), message)
  end
  def term_type(term) do
    cond do
      Kernel.is_nil(term) -> "nil"
      Kernel.is_atom(term) -> "atom"
      Kernel.is_binary(term) -> "binary"
      Kernel.is_boolean(term) -> "boolean"
      Kernel.is_float(term) -> "float"
      Kernel.is_function(term) -> "function"
      Kernel.is_integer(term) -> "integer"
      Kernel.is_list(term) -> "list"
      Kernel.is_map(term) -> "map"
      Kernel.is_pid(term) -> "pid"
      Kernel.is_port(term) -> "port"
      Kernel.is_reference(term) -> "reference"
      Kernel.is_tuple(term) -> "tuple"
      :true -> "unknown"
    end
  end
end
