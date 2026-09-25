defmodule Main do
  def main() do
    if (copy_value("named") != "named!") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "assignment spelling must not discard its value"]
    end
    accepted = Label_Impl_.parse("valid")
    if (Kernel.is_nil(accepted) or accepted != "valid") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "conditional constructor lost its value"]
    end
    if (not Kernel.is_nil(Label_Impl_.parse(""))) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "invalid input was accepted"]
    end
    this1 = Label_Impl_.identity("unchanged")
    if (this1 != "unchanged") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "identity constructor lost its value"]
    end
    this1 = Label_Impl_.choose("left", "right", true)
    if (this1 != "left") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "true branch lost its value"]
    end
    this1 = Label_Impl_.choose("left", "right", false)
    if (this1 != "right") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "false branch lost its value"]
    end
    selected = Label_Impl_.from_code(1, "selected")
    if (Kernel.is_nil(selected) or selected != "selected") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "case constructor lost its value"]
    end
    fixed = Label_Impl_.from_code(2, "ignored")
    if (Kernel.is_nil(fixed) or fixed != "fixed") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "constant constructor changed"]
    end
    if (not Kernel.is_nil(Label_Impl_.from_code(0, "ignored"))) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "case rejection changed"]
    end
  end
  defp copy_value(value) do
    new_query = "#{value}!"
    new_query
  end
end
