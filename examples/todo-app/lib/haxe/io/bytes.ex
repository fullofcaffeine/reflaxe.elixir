defmodule Bytes do
  def get_string(pos, len, encoding) do
    if (encoding == nil) do
      encoding = {:utf8}
    end
    if (:nil < :nil || :nil < :nil || :nil + :nil > length(self)) do
      throw("Out of bounds")
    end
    slice = :binary.part(self.b, pos, len)
    :unicode.characters_to_list(slice, :utf8)
  end
  def to_string() do
    :unicode.characters_to_list(self, :utf8)
  end
  def get(pos) do
    if (pos < 0 || pos >= length(self)) do
      throw("Out of bounds")
    end
    :binary.at(self.b, pos)
  end
  def set(pos, v) do
    if (pos < 0 || pos >= length(self)) do
      throw("Out of bounds")
    end
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(self.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos < (length(self) - 1)) do
      temp_var1 = :binary.part(self.b, pos + 1, ((:nil - :nil) - 1))
    else
      temp_var1 = <<>>
    end
    b = <<tempVar::binary, v::8, tempVar1::binary>>
  end
  def blit(pos, src, srcpos, len) do
    if (:nil || :nil || :nil > :nil || :nil + :nil > length(src)) do
      throw("Out of bounds")
    end
    src_slice = :binary.part(src.b, srcpos, len)
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(self.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos + len < length(self)) do
      temp_var1 = :binary.part(self.b, pos + len, ((:nil - :nil) - len))
    else
      temp_var1 = <<>>
    end
    b = <<tempVar::binary, srcSlice::binary, tempVar1::binary>>
  end
  def sub(pos, len) do
    if (:nil < :nil || :nil < :nil || :nil + :nil > length(self)) do
      throw("Out of bounds")
    end
    sub_binary = :binary.part(self.b, pos, len)
    Bytes.new(len, subBinary)
  end
  def fill(pos, len, value) do
    if (:nil < :nil || :nil < :nil || :nil + :nil > length(self)) do
      throw("Out of bounds")
    end
    fill_bytes = :binary.copy(<<value::8>>, len)
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(self.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos + len < length(self)) do
      temp_var1 = :binary.part(self.b, pos + len, ((:nil - :nil) - len))
    else
      temp_var1 = <<>>
    end
    b = <<tempVar::binary, fillBytes::binary, tempVar1::binary>>
  end
  def compare(other) do
    case self.b do
            x when x < other.b -> -1
            x when x > other.b -> 1
            _ -> 0
        end
  end
  def get_data() do
    struct.b
  end
  def get_double(pos) do
    if (pos < 0 || :nil + :nil > length(self)) do
      throw("Out of bounds")
    end
    <<value::float-little-size(64)>> = :binary.part(self.b, pos, 8); value
  end
  def set_double(pos, v) do
    if (pos < 0 || :nil + :nil > length(self)) do
      throw("Out of bounds")
    end
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(self.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos + 8 < length(self)) do
      temp_var1 = :binary.part(self.b, pos + 8, ((:nil - :nil) - 8))
    else
      temp_var1 = <<>>
    end
    b = <<tempVar::binary, v::float-little-size(64), tempVar1::binary>>
  end
  def get_float(pos) do
    if (pos < 0 || :nil + :nil > length(self)) do
      throw("Out of bounds")
    end
    <<value::float-little-size(32)>> = :binary.part(self.b, pos, 4); value
  end
  def set_float(pos, v) do
    if (pos < 0 || :nil + :nil > length(self)) do
      throw("Out of bounds")
    end
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(self.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos + 4 < length(self)) do
      temp_var1 = :binary.part(self.b, pos + 4, ((:nil - :nil) - 4))
    else
      temp_var1 = <<>>
    end
    b = <<tempVar::binary, v::float-little-size(32), tempVar1::binary>>
  end
  def get_u_int16(pos) do
    if (pos < 0 || :nil + :nil > length(self)) do
      throw("Out of bounds")
    end
    <<value::little-unsigned-size(16)>> = :binary.part(self.b, pos, 2); value
  end
  def set_u_int16(pos, v) do
    if (pos < 0 || :nil + :nil > length(self)) do
      throw("Out of bounds")
    end
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(self.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos + 2 < length(self)) do
      temp_var1 = :binary.part(self.b, pos + 2, ((:nil - :nil) - 2))
    else
      temp_var1 = <<>>
    end
    b = <<tempVar::binary, v::little-unsigned-size(16), tempVar1::binary>>
  end
  def get_int32(pos) do
    if (pos < 0 || :nil + :nil > length(self)) do
      throw("Out of bounds")
    end
    <<value::little-signed-size(32)>> = :binary.part(self.b, pos, 4); value
  end
  def set_int32(pos, v) do
    if (pos < 0 || :nil + :nil > length(self)) do
      throw("Out of bounds")
    end
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(self.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos + 4 < length(self)) do
      temp_var1 = :binary.part(self.b, pos + 4, ((:nil - :nil) - 4))
    else
      temp_var1 = <<>>
    end
    b = <<tempVar::binary, v::little-signed-size(32), tempVar1::binary>>
  end
  def get_int64(pos) do
    if (pos < 0 || :nil + :nil > length(self)) do
      throw("Out of bounds")
    end
    <<value::little-signed-size(64)>> = :binary.part(self.b, pos, 8); value
  end
  def set_int64(pos, v) do
    if (pos < 0 || :nil + :nil > length(self)) do
      throw("Out of bounds")
    end
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(self.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos + 8 < length(self)) do
      temp_var1 = :binary.part(self.b, pos + 8, ((:nil - :nil) - 8))
    else
      temp_var1 = <<>>
    end
    b = <<tempVar::binary, v::little-signed-size(64), tempVar1::binary>>
  end
  def read_string(pos, len) do
    :unicode.characters_to_list(self, :utf8)
  end
  def to_hex() do
    Base.encode16(self.b, case: :lower)
  end
  def alloc(length) do
    Bytes.new(length2, (:binary.copy(<<0>>, length2)))
  end
  def of_string(s, encoding) do
    binary = :unicode.characters_to_binary(s, :utf8)
    length2 = byte_size(binary)
    Bytes.new(length2, binary)
  end
  def fast_get(b, pos) do
    :binary.at(b2, pos)
  end
  def of_hex(s) do
    binary = Base.decode16!(s, case: :mixed)
    length2 = byte_size(binary)
    Bytes.new(length2, binary)
  end
  def of_data(b) do
    Bytes.new((byte_size(b2)), b2)
  end
end