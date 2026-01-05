defmodule GenServerRef_Impl_ do
  import Kernel, except: [to_string: 1], warn: false
  def _new(ref) do
    ref
  end
  def from_pid(pid) do
    
  end
  def from_name(name) do
    
  end
  def from_via(via) do
    
  end
  def global(name) do
    ref = elixir__.("{:global, #{if (name == nil), do: "null", else: name}}")
    ref
  end
  def is_alive(this1) do
    elixir__.("
            case #{Kernel.to_string(this1)} do
                pid when is_pid(pid) -> Process.alive?(pid)
                name when is_atom(name) -> 
                    case Process.whereis(name) do
                        nil -> false
                        pid -> Process.alive?(pid)
                    end
                {:global, name} ->
                    case :global.whereis_name(name) do
                        :undefined -> false
                        pid -> Process.alive?(pid)
                    end
                {:via, module, name} ->
                    case module.whereis_name(name) do
                        :undefined -> false
                        pid -> Process.alive?(pid)
                    end
                _ -> false
            end
        ")
  end
  def whereis(this1) do
    elixir__.("
            case #{Kernel.to_string(this1)} do
                pid when is_pid(pid) -> pid
                name when is_atom(name) -> Process.whereis(name)
                {:global, name} -> :global.whereis_name(name)
                {:via, module, name} -> module.whereis_name(name)
                _ -> nil
            end
        ")
  end
  def to_string(this1) do
    Kernel.inspect(this1)
  end
end
