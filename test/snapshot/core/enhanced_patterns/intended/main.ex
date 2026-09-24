defmodule Main do
  def test_binary_patterns() do
    data = [72, 101, 108, 108, 111]
    switch_result_1 = (case length(data) do
      0 ->
        arr = data
        if (Enum.at(arr, 0) == 72 and length(arr) > 1) do
          "Starts with 'H', rest: " <> Enum.join(
            (fn ->
               g = []
               arr_length = length(arr)
               g = Enum.reduce(1..(arr_length - 1)//1, g, fn i, g_acc -> Enum.concat(g_acc, [Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(arr, i))]) end)
               g
             end).(),
            ","
          )
        else
          "Empty binary"
        end
      1 ->
        array_read_node_0 = Enum.at(data, 0)
        if (array_read_node_0 == 72) do
          "Starts with 'H' (single byte)"
        else
          arr = data
          if (Enum.at(arr, 0) == 72 and length(arr) > 1) do
            "Starts with 'H', rest: " <> Enum.join(
              (fn ->
                 g = []
                 arr_length = length(arr)
                 g = Enum.reduce(1..(arr_length - 1)//1, g, fn i, g_acc -> Enum.concat(g_acc, [Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(arr, i))]) end)
                 g
               end).(),
              ","
            )
          else
            bytes = data
            if (length(bytes) > 10) do
              "Large binary: #{Reflaxe.Elixir.HaxeFloat.to_string(length(bytes))} bytes"
            else
              "Other binary pattern"
            end
          end
        end
      2 ->
        array_read_node_1 = Enum.at(data, 0)
        array_read_node_2 = Enum.at(data, 1)
        arr = data
        if (Enum.at(arr, 0) == 72 and length(arr) > 1) do
          "Starts with 'H', rest: " <> Enum.join(
            (fn ->
               g = []
               arr_length = length(arr)
               g = Enum.reduce(1..(arr_length - 1)//1, g, fn i, g_acc -> Enum.concat(g_acc, [Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(arr, i))]) end)
               g
             end).(),
            ","
          )
        else
          first = array_read_node_1
          _second = array_read_node_2
          if (first > 64 and first < 90) do
            "2-byte uppercase start"
          else
            bytes = data
            if (length(bytes) > 10) do
              "Large binary: #{Reflaxe.Elixir.HaxeFloat.to_string(length(bytes))} bytes"
            else
              "Other binary pattern"
            end
          end
        end
      5 ->
        array_read_node_3 = Enum.at(data, 0)
        array_read_node_4 = Enum.at(data, 1)
        array_read_node_5 = Enum.at(data, 2)
        array_read_node_6 = Enum.at(data, 3)
        array_read_node_7 = Enum.at(data, 4)
        arr = data
        if (Enum.at(arr, 0) == 72 and length(arr) > 1) do
          "Starts with 'H', rest: " <> Enum.join(
            (fn ->
               g = []
               arr_length = length(arr)
               g = Enum.reduce(1..(arr_length - 1)//1, g, fn i, g_acc -> Enum.concat(g_acc, [Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(arr, i))]) end)
               g
             end).(),
            ","
          )
        else
          a = array_read_node_3
          _b = array_read_node_4
          _c = array_read_node_5
          _d = array_read_node_6
          _e = array_read_node_7
          if (a == 72) do
            "5-byte message starting with H"
          else
            bytes = data
            if (length(bytes) > 10) do
              "Large binary: #{Reflaxe.Elixir.HaxeFloat.to_string(length(bytes))} bytes"
            else
              "Other binary pattern"
            end
          end
        end
      _ ->
        arr = data
        if (Enum.at(arr, 0) == 72 and length(arr) > 1) do
          "Starts with 'H', rest: " <> Enum.join(
            (fn ->
               g = []
               arr_length = length(arr)
               g = Enum.reduce(1..(arr_length - 1)//1, g, fn i, g_acc -> Enum.concat(g_acc, [Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(arr, i))]) end)
               g
             end).(),
            ","
          )
        else
          bytes = data
          if (length(bytes) > 10) do
            "Large binary: #{Reflaxe.Elixir.HaxeFloat.to_string(length(bytes))} bytes"
          else
            "Other binary pattern"
          end
        end
    end)
    switch_result_1
  end
  def test_complex_binary_segments() do
    packet = [1, 0, 8, 72, 101, 108, 108, 111]
    switch_result_1 = (case length(packet) do
      3 ->
        array_read_node_8 = Enum.at(packet, 0)
        array_read_node_9 = Enum.at(packet, 1)
        array_read_node_10 = Enum.at(packet, 2)
        if (array_read_node_8 == 1) do
          if (array_read_node_9 == 0) do
            size = array_read_node_10
            "Protocol v1, size=#{Reflaxe.Elixir.HaxeFloat.to_string(size)} (header only)"
          else
            arr = packet
            if (length(arr) >= 4 and Enum.at(arr, 0) == 1 and Enum.at(arr, 1) == 0) do
              "Protocol v1, size=" <> Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(arr, 2)) <> ", data=" <> Enum.join(
                (fn ->
                   g = []
                   arr_length = length(arr)
                   g = Enum.reduce(3..(arr_length - 1)//1, g, fn i, g_acc -> Enum.concat(g_acc, [Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(arr, i))]) end)
                   g
                 end).(),
                ","
              )
            else
              version = array_read_node_8
              _flags = array_read_node_9
              _size = array_read_node_10
              if (version > 1) do
                "Future protocol v#{Reflaxe.Elixir.HaxeFloat.to_string(version)}"
              else
                header = packet
                if (length(header) < 3), do: "Incomplete header", else: "Unknown packet format"
              end
            end
          end
        else
          arr = packet
          if (length(arr) >= 4 and Enum.at(arr, 0) == 1 and Enum.at(arr, 1) == 0) do
            "Protocol v1, size=" <> Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(arr, 2)) <> ", data=" <> Enum.join(
              (fn ->
                 g = []
                 arr_length = length(arr)
                 g = Enum.reduce(3..(arr_length - 1)//1, g, fn i, g_acc -> Enum.concat(g_acc, [Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(arr, i))]) end)
                 g
               end).(),
              ","
            )
          else
            version = array_read_node_8
            _flags = array_read_node_9
            _size = array_read_node_10
            if (version > 1) do
              "Future protocol v#{Reflaxe.Elixir.HaxeFloat.to_string(version)}"
            else
              header = packet
              if (length(header) < 3), do: "Incomplete header", else: "Unknown packet format"
            end
          end
        end
      4 ->
        array_read_node_11 = Enum.at(packet, 0)
        array_read_node_12 = Enum.at(packet, 1)
        array_read_node_13 = Enum.at(packet, 2)
        array_read_node_14 = Enum.at(packet, 3)
        arr = packet
        if (length(arr) >= 4 and Enum.at(arr, 0) == 1 and Enum.at(arr, 1) == 0) do
          "Protocol v1, size=" <> Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(arr, 2)) <> ", data=" <> Enum.join(
            (fn ->
               g = []
               arr_length = length(arr)
               g = Enum.reduce(3..(arr_length - 1)//1, g, fn i, g_acc -> Enum.concat(g_acc, [Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(arr, i))]) end)
               g
             end).(),
            ","
          )
        else
          version = array_read_node_11
          flags = array_read_node_12
          size = array_read_node_13
          _payload = array_read_node_14
          "Packet: v#{Reflaxe.Elixir.HaxeFloat.to_string(version)}, flags=#{Reflaxe.Elixir.HaxeFloat.to_string(flags)}, size=#{Reflaxe.Elixir.HaxeFloat.to_string(size)}"
        end
      _ ->
        arr = packet
        if (length(arr) >= 4 and Enum.at(arr, 0) == 1 and Enum.at(arr, 1) == 0) do
          "Protocol v1, size=" <> Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(arr, 2)) <> ", data=" <> Enum.join(
            (fn ->
               g = []
               arr_length = length(arr)
               g = Enum.reduce(3..(arr_length - 1)//1, g, fn i, g_acc -> Enum.concat(g_acc, [Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(arr, i))]) end)
               g
             end).(),
            ","
          )
        else
          header = packet
          if (length(header) < 3), do: "Incomplete header", else: "Unknown packet format"
        end
    end)
    switch_result_1
  end
  def test_pin_operator_patterns() do
    expected_value = 42
    expected_name = "test"
    test_value = 42
    test_name = "test"
    value = test_value
    result1 = if (value == expected_value), do: "Matches expected value", else: "Different value"
    v = test_value
    n = test_name
    result2 = if (v == expected_value and n == expected_name) do
      "Both match"
    else
      v = test_value
      _ = test_name
      if (v == expected_value) do
        "Value matches, name different"
      else
        _ = test_value
        n = test_name
        if (n == expected_name), do: "Name matches, value different", else: "Neither matches"
      end
    end
    "#{result1} | #{result2}"
  end
  def test_advanced_guards() do
    temperature = 23.5
    humidity = 65
    pressure = 1013.25
    t = temperature
    h = humidity
    _p = pressure
    if (Reflaxe.Elixir.HaxeFloat.gt(t, 20) and Reflaxe.Elixir.HaxeFloat.lt(t, 25) and h >= 60 and h <= 70) do
      "Perfect conditions"
    else
      t = temperature
      h = humidity
      _ = pressure
      if (Reflaxe.Elixir.HaxeFloat.gt(t, 30) or h > 80) do
        "Too hot or humid"
      else
        t = temperature
        h = humidity
        _ = pressure
        if (Reflaxe.Elixir.HaxeFloat.lt(t, 10) or h < 30) do
          "Too cold or dry"
        else
          _ = temperature
          _ = humidity
          p = pressure
          if (Reflaxe.Elixir.HaxeFloat.lt(p, 1000) or Reflaxe.Elixir.HaxeFloat.gt(p, 1020)) do
            "Abnormal pressure"
          else
            t = temperature
            h = humidity
            p = pressure
            if (Reflaxe.Elixir.HaxeFloat.gte(t, 15) and Reflaxe.Elixir.HaxeFloat.lte(t, 25) and h >= 40 and h <= 75 and Reflaxe.Elixir.HaxeFloat.gte(p, 1000) and Reflaxe.Elixir.HaxeFloat.lte(p, 1020)), do: "Acceptable conditions", else: "Unknown conditions"
          end
        end
      end
    end
  end
  def test_type_guards() do
    value = "Hello World"
    v = value
    if (Std.is(v, String) and Reflaxe.Elixir.HaxeFloat.gt((fn
      dyn_obj when is_binary(dyn_obj) ->
        String.length(dyn_obj)
      dyn_obj when is_list(dyn_obj) ->
        length(dyn_obj)
      dyn_obj ->
        (case Map.fetch(dyn_obj, "length") do
          {:ok, dyn_value} -> dyn_value
          _ ->
            Map.get(dyn_obj, :length)
        end)
    end).(v), 10)) do
      "Long string: #{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
    else
      v = value
      if (Std.is(v, String) and Reflaxe.Elixir.HaxeFloat.lte((fn
        dyn_obj when is_binary(dyn_obj) ->
          String.length(dyn_obj)
        dyn_obj when is_list(dyn_obj) ->
          length(dyn_obj)
        dyn_obj ->
          (case Map.fetch(dyn_obj, "length") do
            {:ok, dyn_value} -> dyn_value
            _ ->
              Map.get(dyn_obj, :length)
          end)
      end).(v), 10)) do
        "Short string: #{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
      else
        v = value
        if (Std.is(v, Int) and Reflaxe.Elixir.HaxeFloat.gt(v, 0)) do
          "Positive integer: #{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
        else
          v = value
          if (Std.is(v, Int) and Reflaxe.Elixir.HaxeFloat.lte(v, 0)) do
            "Non-positive integer: #{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
          else
            v = value
            if (Std.is(v, Float)) do
              "Float value: #{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
            else
              v = value
              if (Std.is(v, Bool)) do
                "Boolean value: #{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
              else
                v = value
                cond do
                  Std.is(v, Array) ->
                    "Array with " <> Reflaxe.Elixir.HaxeFloat.to_string((fn
                      dyn_obj when is_binary(dyn_obj) ->
                        String.length(dyn_obj)
                      dyn_obj when is_list(dyn_obj) ->
                        length(dyn_obj)
                      dyn_obj ->
                        (case Map.fetch(dyn_obj, "length") do
                          {:ok, dyn_value} -> dyn_value
                          _ ->
                            Map.get(dyn_obj, :length)
                        end)
                    end).(v)) <> " elements"
                  Reflaxe.Elixir.HaxeFloat.eq(value, nil) -> "Null value"
                  true -> "Unknown type"
                end
              end
            end
          end
        end
      end
    end
  end
  def test_range_guards() do
    score = 85
    s = score
    if (s >= 90 and s <= 100) do
      "Grade A (90-100)"
    else
      s = score
      if (s >= 80 and s < 90) do
        "Grade B (80-89)"
      else
        s = score
        if (s >= 70 and s < 80) do
          "Grade C (70-79)"
        else
          s = score
          if (s >= 60 and s < 70) do
            "Grade D (60-69)"
          else
            s = score
            if (s >= 0 and s < 60) do
              "Grade F (0-59)"
            else
              s = score
              if (s < 0 or s > 100), do: "Invalid score", else: "Unknown score"
            end
          end
        end
      end
    end
  end
  def test_exhaustive_patterns() do
    flag = true
    bool_result = if (flag), do: "True case", else: "False case"
    enum_result = (case 1 do
      0 -> "Inactive"
      1 -> "Active"
      2 -> "Pending"
      3 -> "Error"
      _ -> "Unknown status"
    end)
    arr_0 = 1
    arr_1 = 2
    arr_2 = 3
    array_result = (case 3 do
      0 -> "Empty"
      1 ->
        g = arr_0
        x = g
        "Single: #{Reflaxe.Elixir.HaxeFloat.to_string(x)}"
      2 ->
        g = arr_0
        g_value = arr_1
        x = g
        y = g_value
        "Pair: #{Reflaxe.Elixir.HaxeFloat.to_string(x)},#{Reflaxe.Elixir.HaxeFloat.to_string(y)}"
      3 ->
        g = arr_0
        g_value = arr_1
        g2 = arr_2
        x = g
        y = g_value
        z = g2
        "Triple: #{Reflaxe.Elixir.HaxeFloat.to_string(x)},#{Reflaxe.Elixir.HaxeFloat.to_string(y)},#{Reflaxe.Elixir.HaxeFloat.to_string(z)}"
      _ -> "Other array pattern"
    end)
    "#{bool_result} | #{enum_result} | #{array_result}"
  end
  def test_nested_patterns_with_guards() do
    data_user_age = 28
    data_user_active = true
    g = data_user_age
    g_value = data_user_active
    age = g
    perms = 2
    active = g_value
    if (age >= 18 and age < 25 and perms > 0 and active) do
      "Young adult with permissions"
    else
      age = g
      perms = 2
      active = g_value
      if (age >= 25 and age < 65 and perms >= 2 and active) do
        "Adult with full permissions"
      else
        age = g
        active = g_value
        if (age >= 65 and active) do
          "Senior user"
        else
          _ = g
          _ = g_value
          _ = g
          perms = 2
          _ = g_value
          if (perms == 0), do: "User without permissions", else: "Other user type"
        end
      end
    end
  end
  def test_complex_guard_performance() do
    metrics_cpu = 45.2
    metrics_memory = 68.7
    metrics_disk = 23.1
    metrics_network = 12.8
    g = metrics_cpu
    g_value = metrics_memory
    g_next = metrics_disk
    g_entry = metrics_network
    cpu = g
    mem = g_value
    disk = g_next
    net = g_entry
    if (Reflaxe.Elixir.HaxeFloat.gt(cpu, 80) or Reflaxe.Elixir.HaxeFloat.gt(mem, 90) or Reflaxe.Elixir.HaxeFloat.gt(disk, 90) or Reflaxe.Elixir.HaxeFloat.gt(net, 80)) do
      "Critical resource usage"
    else
      cpu = g
      mem = g_value
      disk = g_next
      net = g_entry
      if (Reflaxe.Elixir.HaxeFloat.gt(cpu, 60) or Reflaxe.Elixir.HaxeFloat.gt(mem, 75) or Reflaxe.Elixir.HaxeFloat.gt(disk, 75) or Reflaxe.Elixir.HaxeFloat.gt(net, 60)) do
        "High resource usage"
      else
        cpu = g
        mem = g_value
        disk = g_next
        net = g_entry
        if (Reflaxe.Elixir.HaxeFloat.gt(cpu, 40) and Reflaxe.Elixir.HaxeFloat.gt(mem, 50) and Reflaxe.Elixir.HaxeFloat.gt(disk, 50) and Reflaxe.Elixir.HaxeFloat.gt(net, 30)) do
          "Moderate resource usage"
        else
          cpu = g
          mem = g_value
          disk = g_next
          net = g_entry
          if (Reflaxe.Elixir.HaxeFloat.lte(cpu, 40) and Reflaxe.Elixir.HaxeFloat.lte(mem, 50) and Reflaxe.Elixir.HaxeFloat.lte(disk, 50) and Reflaxe.Elixir.HaxeFloat.lte(net, 30)), do: "Low resource usage", else: "Unknown resource state"
        end
      end
    end
  end
  defp expect(actual, expected) do
    if (actual != expected) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected \"" <> expected <> "\", got \"" <> actual <> "\""]
    end
  end
  def main() do
    expect(test_binary_patterns(), "Starts with 'H', rest: 101,108,108,111")
    expect(test_complex_binary_segments(), "Protocol v1, size=8, data=72,101,108,108,111")
    expect(test_pin_operator_patterns(), "Matches expected value | Both match")
    expect(test_advanced_guards(), "Perfect conditions")
    expect(test_exhaustive_patterns(), "True case | Active | Triple: 1,2,3")
    expect(test_nested_patterns_with_guards(), "Adult with full permissions")
    nil
  end
end
