defmodule Main do
  def main() do
    _ = test_iteration()
    _ = test_key_value_iteration()
    _ = test_validate_utf8()
  end
  defp test_iteration() do
    text = "Aé🌍中"
    _ = expect("unicode length", String.length(text) == 4)
    codes = []
    g_offset = 0
    g_s = text
    {codes, _g_offset} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {codes, g_offset}, fn _, {acc_codes, acc__g_offset} ->
      try do
        cond_value = (if (acc__g_offset < 0) do
          ""
        else
          String.at(g_s, acc__g_offset) || ""
        end)
        if (cond_value != "") do
          s = g_s
          reflaxe_receiver_value_0 = acc__g_offset
          acc__g_offset = acc__g_offset + 1
          index = reflaxe_receiver_value_0
          code = if (index < 0) do
            nil
          else
            Enum.at(String.to_charlist(s), index)
          end
          acc_codes = acc_codes ++ [code]
          {:cont, {acc_codes, acc__g_offset}}
        else
          {:halt, {acc_codes, acc__g_offset}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_codes, acc__g_offset}}
        :throw, :continue ->
          {:cont, {acc_codes, acc__g_offset}}
      end
    end)
    _ = expect("codepoint count", length(codes) == 4)
    _ = expect("ascii codepoint", Enum.at(codes, 0) == 65)
    _ = expect("latin codepoint", Enum.at(codes, 1) == 233)
    _ = expect("astral codepoint", Enum.at(codes, 2) == 127757)
    _ = expect("cjk codepoint", Enum.at(codes, 3) == 20013)
  end
  defp test_key_value_iteration() do
    text = "a🌍b"
    entries = []
    g_offset = 0
    g_s = text
    {entries, _g_offset} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {entries, g_offset}, fn _, {acc_entries, acc__g_offset} ->
      try do
        cond_value = (if (acc__g_offset < 0) do
          ""
        else
          String.at(g_s, acc__g_offset) || ""
        end)
        if (cond_value != "") do
          g_key = acc__g_offset
          s = g_s
          reflaxe_receiver_value_1 = acc__g_offset
          acc__g_offset = acc__g_offset + 1
          index = reflaxe_receiver_value_1
          g_value = if (index < 0) do
            nil
          else
            Enum.at(String.to_charlist(s), index)
          end
          index = g_key
          code = g_value
          acc_entries = acc_entries ++ [Reflaxe.Elixir.HaxeFloat.to_string(index) <> ":" <> Reflaxe.Elixir.HaxeFloat.to_string(code)]
          {:cont, {acc_entries, acc__g_offset}}
        else
          {:halt, {acc_entries, acc__g_offset}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_entries, acc__g_offset}}
        :throw, :continue ->
          {:cont, {acc_entries, acc__g_offset}}
      end
    end)
    _ = expect("key value count", length(entries) == 3)
    _ = expect("key value ascii", Enum.at(entries, 0) == "0:97")
    _ = expect("key value astral", Enum.at(entries, 1) == "1:127757")
    _ = expect("key value trailing", Enum.at(entries, 2) == "2:98")
  end
  defp test_validate_utf8() do
    valid = Bytes.of_string("Aé🌍中", {:utf8})
    _ = expect("valid utf8", (fn ->
			case {:utf8} do
				{:raw_native} ->
					raise "UnicodeString.validate: RawNative encoding is not supported"
				{:utf16le} ->
					raise "UnicodeString.validate: only UTF8 encoding is supported on the Elixir target"
				{:utf16be} ->
					raise "UnicodeString.validate: only UTF8 encoding is supported on the Elixir target"
				{:utf32le} ->
					raise "UnicodeString.validate: only UTF8 encoding is supported on the Elixir target"
				{:utf32be} ->
					raise "UnicodeString.validate: only UTF8 encoding is supported on the Elixir target"
				{:utf8} ->
					reflaxe_unicode_len = valid.length
					reflaxe_unicode_get = fn pos -> :binary.at(apply(Map.get(valid, :__reflaxe_class__) || Map.get(valid, :__struct__), :get_data, [valid]), pos) end
					reflaxe_unicode_valid = fn reflaxe_unicode_valid, pos ->
						if pos >= reflaxe_unicode_len do
							true
						else
							code = reflaxe_unicode_get.(pos)
							cond do
								code < 0x80 ->
									reflaxe_unicode_valid.(reflaxe_unicode_valid, pos + 1)
								code < 0xC2 ->
									false
								code < 0xE0 ->
									if pos + 1 >= reflaxe_unicode_len do
										false
									else
										code2 = reflaxe_unicode_get.(pos + 1)
										if code2 < 0x80 or code2 > 0xBF do
											false
										else
											reflaxe_unicode_valid.(reflaxe_unicode_valid, pos + 2)
										end
									end
								code < 0xF0 ->
									if pos + 2 >= reflaxe_unicode_len do
										false
									else
										code2 = reflaxe_unicode_get.(pos + 1)
										code3 = reflaxe_unicode_get.(pos + 2)
										code2_valid =
											if code == 0xE0 do
												code2 >= 0xA0 and code2 <= 0xBF
											else
												code2 >= 0x80 and code2 <= 0xBF
											end
										combined = Bitwise.bor(Bitwise.bsl(code, 16), Bitwise.bor(Bitwise.bsl(code2, 8), code3))
										if not code2_valid or code3 < 0x80 or code3 > 0xBF or (0xEDA080 <= combined and combined <= 0xEDBFBF) do
											false
										else
											reflaxe_unicode_valid.(reflaxe_unicode_valid, pos + 3)
										end
									end
								code > 0xF4 ->
									false
								true ->
									if pos + 3 >= reflaxe_unicode_len do
										false
									else
										code2 = reflaxe_unicode_get.(pos + 1)
										code3 = reflaxe_unicode_get.(pos + 2)
										code4 = reflaxe_unicode_get.(pos + 3)
										code2_valid =
											cond do
												code == 0xF0 -> code2 >= 0x90 and code2 <= 0xBF
												code == 0xF4 -> code2 >= 0x80 and code2 <= 0x8F
												true -> code2 >= 0x80 and code2 <= 0xBF
											end
										if not code2_valid or code3 < 0x80 or code3 > 0xBF or code4 < 0x80 or code4 > 0xBF do
											false
										else
											reflaxe_unicode_valid.(reflaxe_unicode_valid, pos + 4)
										end
									end
							end
						end
					end
					reflaxe_unicode_valid.(reflaxe_unicode_valid, 0)
			end
		 end).())
    invalid = %{__reflaxe_class__: Bytes, length: 1, b: <<0xC0>>}
    _ = expect("invalid utf8", (fn -> not 
			case {:utf8} do
				{:raw_native} ->
					raise "UnicodeString.validate: RawNative encoding is not supported"
				{:utf16le} ->
					raise "UnicodeString.validate: only UTF8 encoding is supported on the Elixir target"
				{:utf16be} ->
					raise "UnicodeString.validate: only UTF8 encoding is supported on the Elixir target"
				{:utf32le} ->
					raise "UnicodeString.validate: only UTF8 encoding is supported on the Elixir target"
				{:utf32be} ->
					raise "UnicodeString.validate: only UTF8 encoding is supported on the Elixir target"
				{:utf8} ->
					reflaxe_unicode_len = invalid.length
					reflaxe_unicode_get = fn pos -> :binary.at(apply(Map.get(invalid, :__reflaxe_class__) || Map.get(invalid, :__struct__), :get_data, [invalid]), pos) end
					reflaxe_unicode_valid = fn reflaxe_unicode_valid, pos ->
						if pos >= reflaxe_unicode_len do
							true
						else
							code = reflaxe_unicode_get.(pos)
							cond do
								code < 0x80 ->
									reflaxe_unicode_valid.(reflaxe_unicode_valid, pos + 1)
								code < 0xC2 ->
									false
								code < 0xE0 ->
									if pos + 1 >= reflaxe_unicode_len do
										false
									else
										code2 = reflaxe_unicode_get.(pos + 1)
										if code2 < 0x80 or code2 > 0xBF do
											false
										else
											reflaxe_unicode_valid.(reflaxe_unicode_valid, pos + 2)
										end
									end
								code < 0xF0 ->
									if pos + 2 >= reflaxe_unicode_len do
										false
									else
										code2 = reflaxe_unicode_get.(pos + 1)
										code3 = reflaxe_unicode_get.(pos + 2)
										code2_valid =
											if code == 0xE0 do
												code2 >= 0xA0 and code2 <= 0xBF
											else
												code2 >= 0x80 and code2 <= 0xBF
											end
										combined = Bitwise.bor(Bitwise.bsl(code, 16), Bitwise.bor(Bitwise.bsl(code2, 8), code3))
										if not code2_valid or code3 < 0x80 or code3 > 0xBF or (0xEDA080 <= combined and combined <= 0xEDBFBF) do
											false
										else
											reflaxe_unicode_valid.(reflaxe_unicode_valid, pos + 3)
										end
									end
								code > 0xF4 ->
									false
								true ->
									if pos + 3 >= reflaxe_unicode_len do
										false
									else
										code2 = reflaxe_unicode_get.(pos + 1)
										code3 = reflaxe_unicode_get.(pos + 2)
										code4 = reflaxe_unicode_get.(pos + 3)
										code2_valid =
											cond do
												code == 0xF0 -> code2 >= 0x90 and code2 <= 0xBF
												code == 0xF4 -> code2 >= 0x80 and code2 <= 0x8F
												true -> code2 >= 0x80 and code2 <= 0xBF
											end
										if not code2_valid or code3 < 0x80 or code3 > 0xBF or code4 < 0x80 or code4 > 0xBF do
											false
										else
											reflaxe_unicode_valid.(reflaxe_unicode_valid, pos + 4)
										end
									end
							end
						end
					end
					reflaxe_unicode_valid.(reflaxe_unicode_valid, 0)
			end
		 end).())
  end
  defp expect(label, condition) do
    if not (condition), do: raise("UnicodeString assertion failed: " <> label)
  end
end
