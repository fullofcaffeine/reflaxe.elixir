defmodule Haxe.Crypto.BaseCode do
  def new(base_param) do
    struct = %{:__reflaxe_class__ => Haxe.Crypto.BaseCode, :base => nil, :nbits => nil}
    len = base_param.length
    candidate_bits = 1
    {candidate_bits} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {candidate_bits}, fn _, {acc_candidate_bits} ->
      try do
        if (len > Bitwise.bsl(1, acc_candidate_bits)) do
          acc_candidate_bits = acc_candidate_bits + 1
          {:cont, {acc_candidate_bits}}
        else
          {:halt, {acc_candidate_bits}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_candidate_bits}}
        :throw, :continue ->
          {:cont, {acc_candidate_bits}}
      end
    end)
    if (candidate_bits > 8 or len != Bitwise.bsl(1, candidate_bits)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "BaseCode : base length must be a power of two."]
    end
    struct = %{struct | base: base_param}
    struct = %{struct | nbits: candidate_bits}
    struct
  end
  def encode_bytes(struct, bytes) do
    data = (
          reflaxe_basecode_input = apply(Map.get(bytes, :__reflaxe_class__) || Map.get(bytes, :__struct__), :get_data, [bytes])
          reflaxe_basecode_base = (fn -> reflaxe_dispatch_receiver = struct.base
    apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :get_data, [reflaxe_dispatch_receiver]) end).()
          reflaxe_basecode_nbits = struct.nbits
          reflaxe_basecode_bit_count = byte_size(reflaxe_basecode_input) * 8
          reflaxe_basecode_size = div(reflaxe_basecode_bit_count, reflaxe_basecode_nbits)
          reflaxe_basecode_mask = Bitwise.bsl(1, reflaxe_basecode_nbits) - 1

          reflaxe_basecode_read = fn reflaxe_basecode_read, buf, curbits, pin ->
            if curbits < reflaxe_basecode_nbits do
              reflaxe_basecode_read.(
                reflaxe_basecode_read,
                Bitwise.bor(Bitwise.bsl(buf, 8), :binary.at(reflaxe_basecode_input, pin)),
                curbits + 8,
                pin + 1
              )
            else
              {buf, curbits, pin}
            end
          end

          reflaxe_basecode_encode = fn reflaxe_basecode_encode, remaining, out, buf, curbits, pin ->
            if remaining == 0 do
              {out, buf, curbits, pin}
            else
              {buf, curbits, pin} = reflaxe_basecode_read.(reflaxe_basecode_read, buf, curbits, pin)
              curbits = curbits - reflaxe_basecode_nbits
              value = :binary.at(reflaxe_basecode_base, Bitwise.band(Bitwise.bsr(buf, curbits), reflaxe_basecode_mask))
              reflaxe_basecode_encode.(reflaxe_basecode_encode, remaining - 1, [value | out], buf, curbits, pin)
            end
          end

          {reflaxe_basecode_out, reflaxe_basecode_buf, reflaxe_basecode_curbits, _} =
            reflaxe_basecode_encode.(reflaxe_basecode_encode, reflaxe_basecode_size, [], 0, 0, 0)

          reflaxe_basecode_out =
            if reflaxe_basecode_curbits > 0 do
              value =
                :binary.at(
                  reflaxe_basecode_base,
                  Bitwise.band(Bitwise.bsl(reflaxe_basecode_buf, reflaxe_basecode_nbits - reflaxe_basecode_curbits), reflaxe_basecode_mask)
                )
              [value | reflaxe_basecode_out]
            else
              reflaxe_basecode_out
            end

          :erlang.list_to_binary(Enum.reverse(reflaxe_basecode_out))
    )
    _ = Bytes.of_data(data)
  end
  def decode_bytes(struct, bytes) do
    data = (
          reflaxe_basecode_input = apply(Map.get(bytes, :__reflaxe_class__) || Map.get(bytes, :__struct__), :get_data, [bytes])
          reflaxe_basecode_base = (fn -> reflaxe_dispatch_receiver = struct.base
    apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :get_data, [reflaxe_dispatch_receiver]) end).()
          reflaxe_basecode_nbits = struct.nbits
          reflaxe_basecode_size = div(byte_size(reflaxe_basecode_input) * reflaxe_basecode_nbits, 8)

          reflaxe_basecode_find = fn byte ->
            Enum.find_value(0..(byte_size(reflaxe_basecode_base) - 1)//1, -1, fn index ->
              if :binary.at(reflaxe_basecode_base, index) == byte do
                index
              else
                false
              end
            end)
          end

          reflaxe_basecode_read = fn reflaxe_basecode_read, buf, curbits, pin ->
            if curbits < 8 do
              value = reflaxe_basecode_find.(:binary.at(reflaxe_basecode_input, pin))
              if value == -1 do
                raise Reflaxe.Elixir.HaxeThrow, [value: "BaseCode : invalid encoded char"]
              end
              reflaxe_basecode_read.(
                reflaxe_basecode_read,
                Bitwise.bor(Bitwise.bsl(buf, reflaxe_basecode_nbits), value),
                curbits + reflaxe_basecode_nbits,
                pin + 1
              )
            else
              {buf, curbits, pin}
            end
          end

          reflaxe_basecode_decode = fn reflaxe_basecode_decode, remaining, out, buf, curbits, pin ->
            if remaining == 0 do
              out
            else
              {buf, curbits, pin} = reflaxe_basecode_read.(reflaxe_basecode_read, buf, curbits, pin)
              curbits = curbits - 8
              value = Bitwise.band(Bitwise.bsr(buf, curbits), 0xFF)
              reflaxe_basecode_decode.(reflaxe_basecode_decode, remaining - 1, [value | out], buf, curbits, pin)
            end
          end

          :erlang.list_to_binary(Enum.reverse(reflaxe_basecode_decode.(reflaxe_basecode_decode, reflaxe_basecode_size, [], 0, 0, 0)))
    )
    _ = Bytes.of_data(data)
  end
  def encode_string(struct, s) do
    reflaxe_dispatch_receiver = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :encode_bytes, [struct, Bytes.of_string(s, {:utf8})])
    _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
  end
  def decode_string(struct, s) do
    reflaxe_dispatch_receiver = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :decode_bytes, [struct, Bytes.of_string(s, {:utf8})])
    _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
  end
  def encode(s, base_param) do
    b = Haxe.Crypto.BaseCode.new(Bytes.of_string(base_param, {:utf8}))
    _ = apply(Map.get(b, :__reflaxe_class__) || Map.get(b, :__struct__), :encode_string, [b, s])
  end
  def decode(s, base_param) do
    b = Haxe.Crypto.BaseCode.new(Bytes.of_string(base_param, {:utf8}))
    _ = apply(Map.get(b, :__reflaxe_class__) || Map.get(b, :__struct__), :decode_string, [b, s])
  end
end
