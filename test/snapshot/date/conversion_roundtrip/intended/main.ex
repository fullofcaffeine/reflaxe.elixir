defmodule Main do
  def main() do
    d = DateTime.utc_now()
    iso = d.to_iso8601()
    parsed = Date_Impl_.from_string(iso)
    Log.trace(Std.string(%{:iso => iso, :y => parsed.year, :m => (parsed.month - 1), :dd => parsed.day}), nil)
  end
end