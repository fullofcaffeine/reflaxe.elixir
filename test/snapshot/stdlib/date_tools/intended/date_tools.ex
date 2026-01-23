defmodule DateTools do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, DateTools, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        _ = Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, DateTools, key}
    _ = Process.put(static_key, {:set, value})
    value
  end
  def day_short_names() do
    __haxe_static_get__(:day_short_names, ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
  end
  def day_short_names(value) do
    __haxe_static_put__(:day_short_names, value)
  end
  def day_names() do
    __haxe_static_get__(:day_names, ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"])
  end
  def day_names(value) do
    __haxe_static_put__(:day_names, value)
  end
  def month_short_names() do
    __haxe_static_get__(:month_short_names, ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])
  end
  def month_short_names(value) do
    __haxe_static_put__(:month_short_names, value)
  end
  def month_names() do
    __haxe_static_get__(:month_names, ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"])
  end
  def month_names(value) do
    __haxe_static_put__(:month_names, value)
  end
  def days_of_month() do
    __haxe_static_get__(:days_of_month, [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31])
  end
  def days_of_month(value) do
    __haxe_static_put__(:days_of_month, value)
  end
  defp __format_get(d, e) do
    (case e do
      "%" -> "%"
      "A" ->
        Enum.at(DateTools.day_names(), (fn ->
          date = DateTime.to_date(d)
          dow = Date.day_of_week(date)
          if (dow == 7), do: 0, else: dow
        end).())
      "B" ->
        Enum.at(DateTools.month_names(), (d.month - 1))
      "C" ->
        StringTools.lpad(inspect(trunc(d.year / 100)), "0", 2)
      "D" ->
        __format(d, "%m/%d/%y")
      "F" ->
        __format(d, "%Y-%m-%d")
      "M" ->
        StringTools.lpad(inspect(d.minute), "0", 2)
      "R" ->
        __format(d, "%H:%M")
      "S" ->
        StringTools.lpad(inspect(d.second), "0", 2)
      "T" ->
        __format(d, "%H:%M:%S")
      "Y" ->
        inspect(d.year)
      "a" ->
        Enum.at(DateTools.day_short_names(), (fn ->
          date = DateTime.to_date(d)
          dow = Date.day_of_week(date)
          if (dow == 7), do: 0, else: dow
        end).())
      "d" ->
        StringTools.lpad(inspect(d.day), "0", 2)
      "e" ->
        inspect(d.day)
      "b" ->
        Enum.at(DateTools.month_short_names(), (d.month - 1))
      "h" ->
        Enum.at(DateTools.month_short_names(), (d.month - 1))
      "H" ->
        StringTools.lpad(inspect(d.hour), (if (e == "H"), do: "0", else: " "), 2)
      "k" ->
        StringTools.lpad(inspect(d.hour), (if (e == "H"), do: "0", else: " "), 2)
      "I" ->
        hour = rem(d.hour, 12)
        _ = StringTools.lpad(inspect((if (hour == 0), do: 12, else: hour)), (if (e == "I"), do: "0", else: " "), 2)
      "l" ->
        hour = rem(d.hour, 12)
        _ = StringTools.lpad(inspect((if (hour == 0), do: 12, else: hour)), (if (e == "I"), do: "0", else: " "), 2)
      "m" ->
        StringTools.lpad(inspect((d.month - 1) + 1), "0", 2)
      "n" -> "\n"
      "p" when d.hour > 11 -> "PM"
      "p" -> "AM"
      "r" ->
        __format(d, "%I:%M:%S %p")
      "s" ->
        inspect(trunc(d / 1000))
      "t" -> "\t"
      "u" when d == 0 -> "7"
      "u" ->
        inspect(t)
      "w" ->
        inspect((fn ->
            date = DateTime.to_date(d)
            dow = Date.day_of_week(date)
            if (dow == 7), do: 0, else: dow
          end).())
      "y" ->
        StringTools.lpad(inspect(rem(d.year, 100)), "0", 2)
      _ -> raise Reflaxe.Elixir.HaxeThrow, [value: NotImplementedException.new("Date.format %" <> e <> "- not implemented yet.", nil, %{:file_name => "../../../../std/DateTools.cross.hx", :line_number => 80, :class_name => "DateTools", :method_name => "__format_get"})]
    end)
  end
  defp __format(d, f) do
    result = %StringBuf{}
    p = 0
    {result, p} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, p}, fn _, {acc_result, acc_p} ->
      try do
        next_percent = (case :binary.match(String.slice(f, acc_p..-1), "%") do
          {pos, _} -> pos + acc_p
          :nomatch -> -1
        end)
        if (next_percent < 0) do
          throw({:break, {acc_result, acc_p}})
        end
        _ = StringBuf.add_sub(acc_result, f, acc_p, (next_percent - acc_p))
        _ = StringBuf.add(acc_result, __format_get(d, String.slice(f, next_percent + 1, 1)))
        acc_p = next_percent + 2
        {:cont, {acc_result, acc_p}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_result, acc_p}}
        :throw, :continue ->
          {:cont, {acc_result, acc_p}}
      end
    end)
    _ = StringBuf.add_sub(result, f, p, (String.length(f) - p))
    _ = StringBuf.to_string(result)
  end
  def format(d, f) do
    __format(d, f)
  end
  def delta(d, t) do
    Date_Impl_.from_time(d + t)
  end
  def get_month_days(d) do
    month = (d.month - 1)
    year = d.year
    if (month != 1) do
      DateTools.days_of_month()[month]
    else
      is_leap = rem(year, 4) == 0 and rem(year, 100) != 0 or rem(year, 400) == 0
      if (is_leap), do: 29, else: 28
    end
  end
  def seconds(n) do
    n * 1000
  end
  def minutes(n) do
    n * 60 * 1000
  end
  def hours(n) do
    n * 60 * 60 * 1000
  end
  def days(n) do
    n * 24 * 60 * 60 * 1000
  end
  def parse(t) do
    s = t / 1000
    m = s / 60
    h = m / 60
    %{:ms => rem(t, 1000), :seconds => trunc(rem(s, 60)), :minutes => trunc(rem(m, 60)), :hours => trunc(rem(h, 24)), :days => trunc(h / 24)}
  end
  def make(o) do
    o.ms + 1000 * (o.seconds + 60 * (o.minutes + 60 * (o.hours + 24 * o.days)))
  end
  def make_utc(year, month, day, hour, min, sec) do
    (fn ->
      elixir_month = month + 1
      
            {:ok, naive} = NaiveDateTime.new(year, elixir_month, day, hour, min, sec)
            DateTime.from_naive!(naive, "Etc/UTC")
    end).()
  end
end
