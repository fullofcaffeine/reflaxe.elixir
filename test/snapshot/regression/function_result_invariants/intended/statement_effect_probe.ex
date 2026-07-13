defmodule StatementEffectProbe do
  def reset() do
    Process.put("reflaxe_statement_effect_probe", 0)
  end
  def record(value) do
    current = Process.get("reflaxe_statement_effect_probe", 0)
    Process.put("reflaxe_statement_effect_probe", current * 10 + value)
    value
  end
  def tail_record(value) do
    record(value)
  end
  def current() do
    Process.get("reflaxe_statement_effect_probe", 0)
  end
end
