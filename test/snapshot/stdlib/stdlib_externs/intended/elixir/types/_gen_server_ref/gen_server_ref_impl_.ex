defmodule GenServerRef_Impl_ do
  def _new(ref) do
    this1 = nil
    this1 = ref
    this1
  end
  def from_pid(pid) do
    this1 = nil
    this1 = pid
    this1
  end
  def from_name(name) do
    ref = __elixir__.call("String.to_atom(" <> name <> ")")
    this1 = nil
    this1 = ref
    this1
  end
  def from_via(via) do
    this1 = nil
    this1 = via
    this1
  end
  def global(name) do
    ref = __elixir__.call("{:global, String.to_atom(" <> name <> ")}")
    this1 = nil
    this1 = ref
    this1
  end
  def is_alive(this1) do
    __elixir__.call("\n            case " <> Std.string(this1) <> " do\n                pid when is_pid(pid) -> Process.alive?(pid)\n                name when is_atom(name) -> \n                    case Process.whereis(name) do\n                        nil -> false\n                        pid -> Process.alive?(pid)\n                    end\n                {:global, name} ->\n                    case :global.whereis_name(name) do\n                        :undefined -> false\n                        pid -> Process.alive?(pid)\n                    end\n                {:via, module, name} ->\n                    case module.whereis_name(name) do\n                        :undefined -> false\n                        pid -> Process.alive?(pid)\n                    end\n                _ -> false\n            end\n        ")
  end
  def whereis(this1) do
    __elixir__.call("\n            case " <> Std.string(this1) <> " do\n                pid when is_pid(pid) -> pid\n                name when is_atom(name) -> Process.whereis(name)\n                {:global, name} -> :global.whereis_name(name)\n                {:via, module, name} -> module.whereis_name(name)\n                _ -> nil\n            end\n        ")
  end
  def to_string(this1) do
    __elixir__.call("inspect(" <> Std.string(this1) <> ")")
  end
end