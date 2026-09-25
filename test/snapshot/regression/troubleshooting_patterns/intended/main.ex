defmodule Main do
  def test_exhaustive_enum_handling() do
    (case {:active} do
      {:active} -> "System is running"
      {:inactive} -> "System is stopped"
      {:pending} -> "System is starting"
      {:suspended} -> "System is paused"
    end)
  end
  def test_result_exhaustiveness(api_result) do
    (case api_result do
      {:ok, value} -> "Success: #{value}"
      {:error, message} -> "Failed: #{message}"
    end)
  end
  def test_guard_clauses() do
    value = 42
    n = value
    if (n < 0) do
      "Negative number"
    else
      n = value
      if (n == 0) do
        "Zero"
      else
        n = value
        if (n > 0 and n <= 10) do
          "Small positive"
        else
          n = value
          if (n > 10 and n <= 100) do
            "Medium positive"
          else
            n = value
            if (n > 100), do: "Large positive", else: "Unexpected value"
          end
        end
      end
    end
  end
  def test_complex_guards(user) do
    user_age = user.age
    user_verified = user.verified
    age = user_age
    _verified = user_verified
    if (age < 13) do
      "Child account"
    else
      (case user_verified do
        false ->
          age = user_age
          if (age >= 13 and age < 18) do
            "Unverified teen"
          else
            age = user_age
            if (age >= 18), do: "Unverified adult", else: "Unknown user type"
          end
        true ->
          age = user_age
          if (age >= 13 and age < 18) do
            "Verified teen"
          else
            age = user_age
            if (age >= 18 and age < 65) do
              "Verified adult"
            else
              age = user_age
              if (age >= 65), do: "Senior user", else: "Unknown user type"
            end
          end
        _ -> "Unknown user type"
      end)
    end
  end
  def test_binary_data_patterns() do
    header_0 = 255
    header_1 = 254
    header_2 = 4
    header_3 = 0
    switch_result_1 = (case 9 do
      3 ->
        g = header_0
        g_value = header_1
        g2 = header_2
        cond do
          g == 255 ->
            other = g_value
            _rest = g2
            cond do
              other != 254 -> "Invalid magic byte: 0x" <> StringTools.hex(other, 2)
              true -> "Unknown packet format"
            end
          true -> "Unknown packet format"
        end
      4 ->
        g = header_0
        g_value = header_1
        g2 = header_2
        g3 = header_3
        cond do
          g == 255 ->
            cond do
              g_value == 254 ->
                length = g2
                version = g3
                if (version == 0 and true) do
                  "Protocol v0, length=" <> Reflaxe.Elixir.HaxeFloat.to_string(length) <> ", payload bytes=" <> Reflaxe.Elixir.HaxeFloat.to_string(5)
                else
                  _ = g2
                  version = g3
                  cond do
                    version > 0 -> "Future protocol v" <> Reflaxe.Elixir.HaxeFloat.to_string(version)
                    true -> "Unknown packet format"
                  end
                end
              true -> "Unknown packet format"
            end
          true -> "Unknown packet format"
        end
      _ -> "Unknown packet format"
    end)
    switch_result_1
  end
  def test_binary_segments() do
    request = [71, 69, 84, 32, 47, 97, 112, 105, 32, 72, 84, 84, 80]
    if (length(request) == 4) do
      array_read_node_0 = Enum.at(request, 0)
      array_read_node_1 = Enum.at(request, 1)
      array_read_node_2 = Enum.at(request, 2)
      array_read_node_3 = Enum.at(request, 3)
      (case array_read_node_0 do
        71 ->
          if (array_read_node_1 == 69) do
            if (array_read_node_2 == 84) do
              if (array_read_node_3 == 32) do
                "GET request detected"
              else
                method1 = array_read_node_0
                method2 = array_read_node_1
                method3 = array_read_node_2
                method4 = array_read_node_3
                if (length(request) >= 4) do
                  "Other method: #{<<method1::utf8>>}#{<<method2::utf8>>}#{<<method3::utf8>>}#{<<method4::utf8>>}"
                else
                  arr = request
                  if (length(arr) >= 9) do
                    "Full HTTP request: " <> Enum.join(
                      (fn ->
                         g = []
                         g2 = (fn array_slice_values_node_4, array_slice_start_node_5, array_slice_end_node_6 ->
                           array_slice_length_node_7 = length(array_slice_values_node_4)
                           array_slice_first_node_8 = min(array_slice_length_node_7, max(0, (if (array_slice_start_node_5 < 0), do: array_slice_length_node_7 + array_slice_start_node_5, else: array_slice_start_node_5)))
                           array_slice_last_node_9 = min(array_slice_length_node_7, max(0, (if (array_slice_end_node_6 < 0), do: array_slice_length_node_7 + array_slice_end_node_6, else: array_slice_end_node_6)))
                           Enum.slice(array_slice_values_node_4, array_slice_first_node_8, max(0, (array_slice_last_node_9 - array_slice_first_node_8)))
                         end).(arr, 0, 4)
                         g = Enum.reduce(g2, g, fn b, g_acc -> Enum.concat(g_acc, [<<b::utf8>>]) end)
                         g
                       end).(),
                      ""
                    ) <> " + more data"
                  else
                    "Invalid HTTP request"
                  end
                end
              end
            else
              method1 = array_read_node_0
              method2 = array_read_node_1
              method3 = array_read_node_2
              method4 = array_read_node_3
              if (length(request) >= 4) do
                "Other method: #{<<method1::utf8>>}#{<<method2::utf8>>}#{<<method3::utf8>>}#{<<method4::utf8>>}"
              else
                arr = request
                if (length(arr) >= 9) do
                  "Full HTTP request: " <> Enum.join(
                    (fn ->
                       g = []
                       g2 = (fn array_slice_values_node_10, array_slice_start_node_11, array_slice_end_node_12 ->
                         array_slice_length_node_13 = length(array_slice_values_node_10)
                         array_slice_first_node_14 = min(array_slice_length_node_13, max(0, (if (array_slice_start_node_11 < 0), do: array_slice_length_node_13 + array_slice_start_node_11, else: array_slice_start_node_11)))
                         array_slice_last_node_15 = min(array_slice_length_node_13, max(0, (if (array_slice_end_node_12 < 0), do: array_slice_length_node_13 + array_slice_end_node_12, else: array_slice_end_node_12)))
                         Enum.slice(array_slice_values_node_10, array_slice_first_node_14, max(0, (array_slice_last_node_15 - array_slice_first_node_14)))
                       end).(arr, 0, 4)
                       g = Enum.reduce(g2, g, fn b, g_acc -> Enum.concat(g_acc, [<<b::utf8>>]) end)
                       g
                     end).(),
                    ""
                  ) <> " + more data"
                else
                  "Invalid HTTP request"
                end
              end
            end
          else
            method1 = array_read_node_0
            method2 = array_read_node_1
            method3 = array_read_node_2
            method4 = array_read_node_3
            if (length(request) >= 4) do
              "Other method: #{<<method1::utf8>>}#{<<method2::utf8>>}#{<<method3::utf8>>}#{<<method4::utf8>>}"
            else
              arr = request
              if (length(arr) >= 9) do
                "Full HTTP request: " <> Enum.join(
                  (fn ->
                     g = []
                     g2 = (fn array_slice_values_node_16, array_slice_start_node_17, array_slice_end_node_18 ->
                       array_slice_length_node_19 = length(array_slice_values_node_16)
                       array_slice_first_node_20 = min(array_slice_length_node_19, max(0, (if (array_slice_start_node_17 < 0), do: array_slice_length_node_19 + array_slice_start_node_17, else: array_slice_start_node_17)))
                       array_slice_last_node_21 = min(array_slice_length_node_19, max(0, (if (array_slice_end_node_18 < 0), do: array_slice_length_node_19 + array_slice_end_node_18, else: array_slice_end_node_18)))
                       Enum.slice(array_slice_values_node_16, array_slice_first_node_20, max(0, (array_slice_last_node_21 - array_slice_first_node_20)))
                     end).(arr, 0, 4)
                     g = Enum.reduce(g2, g, fn b, g_acc -> Enum.concat(g_acc, [<<b::utf8>>]) end)
                     g
                   end).(),
                  ""
                ) <> " + more data"
              else
                "Invalid HTTP request"
              end
            end
          end
        80 ->
          if (array_read_node_1 == 79) do
            if (array_read_node_2 == 83) do
              if (array_read_node_3 == 84) do
                "POST request detected"
              else
                method1 = array_read_node_0
                method2 = array_read_node_1
                method3 = array_read_node_2
                method4 = array_read_node_3
                if (length(request) >= 4) do
                  "Other method: #{<<method1::utf8>>}#{<<method2::utf8>>}#{<<method3::utf8>>}#{<<method4::utf8>>}"
                else
                  arr = request
                  if (length(arr) >= 9) do
                    "Full HTTP request: " <> Enum.join(
                      (fn ->
                         g = []
                         g2 = (fn array_slice_values_node_22, array_slice_start_node_23, array_slice_end_node_24 ->
                           array_slice_length_node_25 = length(array_slice_values_node_22)
                           array_slice_first_node_26 = min(array_slice_length_node_25, max(0, (if (array_slice_start_node_23 < 0), do: array_slice_length_node_25 + array_slice_start_node_23, else: array_slice_start_node_23)))
                           array_slice_last_node_27 = min(array_slice_length_node_25, max(0, (if (array_slice_end_node_24 < 0), do: array_slice_length_node_25 + array_slice_end_node_24, else: array_slice_end_node_24)))
                           Enum.slice(array_slice_values_node_22, array_slice_first_node_26, max(0, (array_slice_last_node_27 - array_slice_first_node_26)))
                         end).(arr, 0, 4)
                         g = Enum.reduce(g2, g, fn b, g_acc -> Enum.concat(g_acc, [<<b::utf8>>]) end)
                         g
                       end).(),
                      ""
                    ) <> " + more data"
                  else
                    "Invalid HTTP request"
                  end
                end
              end
            else
              method1 = array_read_node_0
              method2 = array_read_node_1
              method3 = array_read_node_2
              method4 = array_read_node_3
              if (length(request) >= 4) do
                "Other method: #{<<method1::utf8>>}#{<<method2::utf8>>}#{<<method3::utf8>>}#{<<method4::utf8>>}"
              else
                arr = request
                if (length(arr) >= 9) do
                  "Full HTTP request: " <> Enum.join(
                    (fn ->
                       g = []
                       g2 = (fn array_slice_values_node_28, array_slice_start_node_29, array_slice_end_node_30 ->
                         array_slice_length_node_31 = length(array_slice_values_node_28)
                         array_slice_first_node_32 = min(array_slice_length_node_31, max(0, (if (array_slice_start_node_29 < 0), do: array_slice_length_node_31 + array_slice_start_node_29, else: array_slice_start_node_29)))
                         array_slice_last_node_33 = min(array_slice_length_node_31, max(0, (if (array_slice_end_node_30 < 0), do: array_slice_length_node_31 + array_slice_end_node_30, else: array_slice_end_node_30)))
                         Enum.slice(array_slice_values_node_28, array_slice_first_node_32, max(0, (array_slice_last_node_33 - array_slice_first_node_32)))
                       end).(arr, 0, 4)
                       g = Enum.reduce(g2, g, fn b, g_acc -> Enum.concat(g_acc, [<<b::utf8>>]) end)
                       g
                     end).(),
                    ""
                  ) <> " + more data"
                else
                  "Invalid HTTP request"
                end
              end
            end
          else
            method1 = array_read_node_0
            method2 = array_read_node_1
            method3 = array_read_node_2
            method4 = array_read_node_3
            if (length(request) >= 4) do
              "Other method: #{<<method1::utf8>>}#{<<method2::utf8>>}#{<<method3::utf8>>}#{<<method4::utf8>>}"
            else
              arr = request
              if (length(arr) >= 9) do
                "Full HTTP request: " <> Enum.join(
                  (fn ->
                     g = []
                     g2 = (fn array_slice_values_node_34, array_slice_start_node_35, array_slice_end_node_36 ->
                       array_slice_length_node_37 = length(array_slice_values_node_34)
                       array_slice_first_node_38 = min(array_slice_length_node_37, max(0, (if (array_slice_start_node_35 < 0), do: array_slice_length_node_37 + array_slice_start_node_35, else: array_slice_start_node_35)))
                       array_slice_last_node_39 = min(array_slice_length_node_37, max(0, (if (array_slice_end_node_36 < 0), do: array_slice_length_node_37 + array_slice_end_node_36, else: array_slice_end_node_36)))
                       Enum.slice(array_slice_values_node_34, array_slice_first_node_38, max(0, (array_slice_last_node_39 - array_slice_first_node_38)))
                     end).(arr, 0, 4)
                     g = Enum.reduce(g2, g, fn b, g_acc -> Enum.concat(g_acc, [<<b::utf8>>]) end)
                     g
                   end).(),
                  ""
                ) <> " + more data"
              else
                "Invalid HTTP request"
              end
            end
          end
        _ ->
          method1 = array_read_node_0
          method2 = array_read_node_1
          method3 = array_read_node_2
          method4 = array_read_node_3
          if (length(request) >= 4) do
            "Other method: #{<<method1::utf8>>}#{<<method2::utf8>>}#{<<method3::utf8>>}#{<<method4::utf8>>}"
          else
            arr = request
            if (length(arr) >= 9) do
              "Full HTTP request: " <> Enum.join(
                (fn ->
                   g = []
                   g2 = (fn array_slice_values_node_40, array_slice_start_node_41, array_slice_end_node_42 ->
                     array_slice_length_node_43 = length(array_slice_values_node_40)
                     array_slice_first_node_44 = min(array_slice_length_node_43, max(0, (if (array_slice_start_node_41 < 0), do: array_slice_length_node_43 + array_slice_start_node_41, else: array_slice_start_node_41)))
                     array_slice_last_node_45 = min(array_slice_length_node_43, max(0, (if (array_slice_end_node_42 < 0), do: array_slice_length_node_43 + array_slice_end_node_42, else: array_slice_end_node_42)))
                     Enum.slice(array_slice_values_node_40, array_slice_first_node_44, max(0, (array_slice_last_node_45 - array_slice_first_node_44)))
                   end).(arr, 0, 4)
                   g = Enum.reduce(g2, g, fn b, g_acc -> Enum.concat(g_acc, [<<b::utf8>>]) end)
                   g
                 end).(),
                ""
              ) <> " + more data"
            else
              "Invalid HTTP request"
            end
          end
      end)
    else
      arr = request
      if (length(arr) >= 9) do
        "Full HTTP request: " <> Enum.join(
          (fn ->
             g = []
             g2 = (fn array_slice_values_node_46, array_slice_start_node_47, array_slice_end_node_48 ->
               array_slice_length_node_49 = length(array_slice_values_node_46)
               array_slice_first_node_50 = min(array_slice_length_node_49, max(0, (if (array_slice_start_node_47 < 0), do: array_slice_length_node_49 + array_slice_start_node_47, else: array_slice_start_node_47)))
               array_slice_last_node_51 = min(array_slice_length_node_49, max(0, (if (array_slice_end_node_48 < 0), do: array_slice_length_node_49 + array_slice_end_node_48, else: array_slice_end_node_48)))
               Enum.slice(array_slice_values_node_46, array_slice_first_node_50, max(0, (array_slice_last_node_51 - array_slice_first_node_50)))
             end).(arr, 0, 4)
             g = Enum.reduce(g2, g, fn b, g_acc -> Enum.concat(g_acc, [<<b::utf8>>]) end)
             g
           end).(),
          ""
        ) <> " + more data"
      else
        "Invalid HTTP request"
      end
    end
  end
  def test_pattern_matching_edge_cases() do
    data = [1, [2, 3], %{name: "test", value: 42}]
    switch_result_1 = (case (fn
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
    end).(data) do
      0 ->
        arr = data
        if (Std.is(arr, Array) and Reflaxe.Elixir.HaxeFloat.gt((fn
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
        end).(arr), 3)) do
          "Large array with " <> Reflaxe.Elixir.HaxeFloat.to_string((fn
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
          end).(arr)) <> " elements"
        else
          "Empty array"
        end
      1 ->
        dynamic_array_value_node_52 = data
        dynamic_array_index_node_52 = 0
        array_read_node_53 = (case {dynamic_array_value_node_52, dynamic_array_index_node_52} do
          {dynamic_array_value_node_52, dynamic_array_index_node_52} when is_list(dynamic_array_value_node_52) and is_integer(dynamic_array_index_node_52) ->
            cond do
              dynamic_array_index_node_52 < 0 -> nil
              true -> Enum.at(dynamic_array_value_node_52, dynamic_array_index_node_52)
            end
          {dynamic_array_value_node_52, dynamic_array_index_node_52} -> dynamic_array_value_node_52[dynamic_array_index_node_52]
        end)
        x = array_read_node_53
        if (Std.is(x, Int)) do
          "Single integer: #{Reflaxe.Elixir.HaxeFloat.to_string(x)}"
        else
          arr = data
          if (Std.is(arr, Array) and Reflaxe.Elixir.HaxeFloat.gt((fn
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
          end).(arr), 3)) do
            "Large array with " <> Reflaxe.Elixir.HaxeFloat.to_string((fn
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
            end).(arr)) <> " elements"
          else
            "Other data structure"
          end
        end
      2 ->
        dynamic_array_value_node_59 = data
        dynamic_array_index_node_59 = 0
        array_read_node_54 = (case {dynamic_array_value_node_59, dynamic_array_index_node_59} do
          {dynamic_array_value_node_59, dynamic_array_index_node_59} when is_list(dynamic_array_value_node_59) and is_integer(dynamic_array_index_node_59) ->
            cond do
              dynamic_array_index_node_59 < 0 -> nil
              true -> Enum.at(dynamic_array_value_node_59, dynamic_array_index_node_59)
            end
          {dynamic_array_value_node_59, dynamic_array_index_node_59} -> dynamic_array_value_node_59[dynamic_array_index_node_59]
        end)
        dynamic_array_value_node_60 = data
        dynamic_array_index_node_60 = 1
        array_read_node_55 = (case {dynamic_array_value_node_60, dynamic_array_index_node_60} do
          {dynamic_array_value_node_60, dynamic_array_index_node_60} when is_list(dynamic_array_value_node_60) and is_integer(dynamic_array_index_node_60) ->
            cond do
              dynamic_array_index_node_60 < 0 -> nil
              true -> Enum.at(dynamic_array_value_node_60, dynamic_array_index_node_60)
            end
          {dynamic_array_value_node_60, dynamic_array_index_node_60} -> dynamic_array_value_node_60[dynamic_array_index_node_60]
        end)
        x = array_read_node_54
        y = array_read_node_55
        if (Std.is(x, Int) and Std.is(y, Array)) do
          "Integer and array: " <> Reflaxe.Elixir.HaxeFloat.to_string(x) <> ", [" <> Reflaxe.Elixir.HaxeFloat.to_string((case y do
            dyn_obj ->
              (case Map.fetch(dyn_obj, "join") do
                {:ok, dyn_value} -> dyn_value
                _ ->
                  Map.get(dyn_obj, :join)
              end)
          end).(",")) <> "]"
        else
          arr = data
          if (Std.is(arr, Array) and Reflaxe.Elixir.HaxeFloat.gt((fn
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
          end).(arr), 3)) do
            "Large array with " <> Reflaxe.Elixir.HaxeFloat.to_string((fn
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
            end).(arr)) <> " elements"
          else
            "Other data structure"
          end
        end
      3 ->
        dynamic_array_value_node_61 = data
        dynamic_array_index_node_61 = 0
        array_read_node_56 = (case {dynamic_array_value_node_61, dynamic_array_index_node_61} do
          {dynamic_array_value_node_61, dynamic_array_index_node_61} when is_list(dynamic_array_value_node_61) and is_integer(dynamic_array_index_node_61) ->
            cond do
              dynamic_array_index_node_61 < 0 -> nil
              true -> Enum.at(dynamic_array_value_node_61, dynamic_array_index_node_61)
            end
          {dynamic_array_value_node_61, dynamic_array_index_node_61} -> dynamic_array_value_node_61[dynamic_array_index_node_61]
        end)
        dynamic_array_value_node_62 = data
        dynamic_array_index_node_62 = 1
        array_read_node_57 = (case {dynamic_array_value_node_62, dynamic_array_index_node_62} do
          {dynamic_array_value_node_62, dynamic_array_index_node_62} when is_list(dynamic_array_value_node_62) and is_integer(dynamic_array_index_node_62) ->
            cond do
              dynamic_array_index_node_62 < 0 -> nil
              true -> Enum.at(dynamic_array_value_node_62, dynamic_array_index_node_62)
            end
          {dynamic_array_value_node_62, dynamic_array_index_node_62} -> dynamic_array_value_node_62[dynamic_array_index_node_62]
        end)
        dynamic_array_value_node_63 = data
        dynamic_array_index_node_63 = 2
        array_read_node_58 = (case {dynamic_array_value_node_63, dynamic_array_index_node_63} do
          {dynamic_array_value_node_63, dynamic_array_index_node_63} when is_list(dynamic_array_value_node_63) and is_integer(dynamic_array_index_node_63) ->
            cond do
              dynamic_array_index_node_63 < 0 -> nil
              true -> Enum.at(dynamic_array_value_node_63, dynamic_array_index_node_63)
            end
          {dynamic_array_value_node_63, dynamic_array_index_node_63} -> dynamic_array_value_node_63[dynamic_array_index_node_63]
        end)
        _x = array_read_node_56
        _y = array_read_node_57
        z = array_read_node_58
        if ((Std.is(z, Dynamic) and Reflaxe.Elixir.HaxeFloat.neq(((case z do
          dyn_obj ->
            (case Map.fetch(dyn_obj, "name") do
              {:ok, dyn_value} -> dyn_value
              _ ->
                Map.get(dyn_obj, :name)
            end)
        end)), nil))) do
          "Three elements ending with object: " <> Reflaxe.Elixir.HaxeFloat.to_string(((case z do
            dyn_obj ->
              (case Map.fetch(dyn_obj, "name") do
                {:ok, dyn_value} -> dyn_value
                _ ->
                  Map.get(dyn_obj, :name)
              end)
          end)))
        else
          arr = data
          if (Std.is(arr, Array) and Reflaxe.Elixir.HaxeFloat.gt((fn
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
          end).(arr), 3)) do
            "Large array with " <> Reflaxe.Elixir.HaxeFloat.to_string((fn
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
            end).(arr)) <> " elements"
          else
            "Other data structure"
          end
        end
      _ ->
        arr = data
        if (Std.is(arr, Array) and Reflaxe.Elixir.HaxeFloat.gt((fn
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
        end).(arr), 3)) do
          "Large array with " <> Reflaxe.Elixir.HaxeFloat.to_string((fn
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
          end).(arr)) <> " elements"
        else
          "Other data structure"
        end
    end)
    switch_result_1
  end
  def test_proper_syntax_handling() do
    value = 42
    switch_result_1 = (case value do
      0 -> "zero"
      1 -> "small numbers"
      2 -> "small numbers"
      3 -> "small numbers"
      _ ->
        n = value
        if (n > 10) do
          "large number: #{Reflaxe.Elixir.HaxeFloat.to_string(n)}"
        else
          "other number: #{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
        end
    end)
    switch_result_1
  end
  def test_pattern_matching_performance() do
    operations = [%{type: "read", resource: "user", id: 123}, %{type: "write", resource: "post", id: 456}, %{type: "delete", resource: "comment", id: 789}, %{type: "update", resource: "user", id: 123}]
    results = []
    results = Enum.reduce(operations, results, fn op, results_acc ->
      op_type = op.type
      op_resource = op.resource
      result = (case op_type do
        "delete" ->
          if (op_resource == "comment") do
            "Deleting comment " <> Reflaxe.Elixir.HaxeFloat.to_string(op.id)
          else
            type = op_type
            resource = op_resource
            "Unknown operation: " <> type <> " on " <> resource
          end
        "read" ->
          if (op_resource == "user") do
            "Reading user " <> Reflaxe.Elixir.HaxeFloat.to_string(op.id)
          else
            type = op_type
            resource = op_resource
            "Unknown operation: " <> type <> " on " <> resource
          end
        "update" ->
          if (op_resource == "user") do
            "Updating user " <> Reflaxe.Elixir.HaxeFloat.to_string(op.id)
          else
            type = op_type
            resource = op_resource
            "Unknown operation: " <> type <> " on " <> resource
          end
        "write" ->
          if (op_resource == "post") do
            "Writing post " <> Reflaxe.Elixir.HaxeFloat.to_string(op.id)
          else
            type = op_type
            resource = op_resource
            "Unknown operation: " <> type <> " on " <> resource
          end
        _ ->
          type = op_type
          resource = op_resource
          "Unknown operation: " <> type <> " on " <> resource
      end)
      Enum.concat(results_acc, [result])
    end)
    Enum.join(results, "; ")
  end
  def main() do
    assert_text(test_result_exhaustiveness({:ok, "Success"}), "Success: Success")
    assert_text(test_result_exhaustiveness({:error, "offline"}), "Failed: offline")
    assert_text(test_complex_guards(%{name: "child", age: 10, verified: false}), "Child account")
    assert_text(test_complex_guards(%{name: "teen", age: 15, verified: false}), "Unverified teen")
    assert_text(test_complex_guards(%{name: "teen", age: 15, verified: true}), "Verified teen")
    assert_text(test_complex_guards(%{name: "adult", age: 25, verified: false}), "Unverified adult")
    assert_text(test_complex_guards(%{name: "adult", age: 25, verified: true}), "Verified adult")
    assert_text(test_complex_guards(%{name: "senior", age: 70, verified: true}), "Senior user")
    assert_text(test_pattern_matching_edge_cases(), "Three elements ending with object: test")
    nil
  end
  defp assert_text(actual, expected) do
    if (actual != expected) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected " <> expected <> ", got " <> actual]
    end
  end
end
