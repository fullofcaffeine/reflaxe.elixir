defmodule GenServerRef_Impl_ do
  import Kernel, except: [to_string: 1], warn: false
  def _new(ref) do
    ref
  end
  def from_pid(pid) do
    pid
  end
  def from_name(name) do
    name
  end
  def from_via(via) do
    via
  end
  def global(name) do
    ref = elixir__.("{:global, #{if (name == nil), do: "null", else: name}}")
    ref
  end
  def is_alive(this1) do
    elixir__.("\n            case #{Reflaxe.Elixir.HaxeFloat.to_string(this1)} do\n                pid when is_pid(pid) -> Process.alive?(pid)\n                name when is_atom(name) -> \n                    case Process.whereis(name) do\n                        nil -> false\n                        pid -> Process.alive?(pid)\n                    end\n                {:global, name} ->\n                    case :global.whereis_name(name) do\n                        :undefined -> false\n                        pid -> Process.alive?(pid)\n                    end\n                {:via, module, name} ->\n                    case module.whereis_name(name) do\n                        :undefined -> false\n                        pid -> Process.alive?(pid)\n                    end\n                _ -> false\n            end\n        ")
  end
  def whereis(this1) do
    elixir__.("\n            case #{Reflaxe.Elixir.HaxeFloat.to_string(this1)} do\n                pid when is_pid(pid) -> pid\n                name when is_atom(name) -> Process.whereis(name)\n                {:global, name} -> :global.whereis_name(name)\n                {:via, module, name} -> module.whereis_name(name)\n                _ -> nil\n            end\n        ")
  end
  def to_string(this1) do
    Kernel.inspect(this1)
  end
end
