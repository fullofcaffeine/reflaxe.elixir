defmodule Bytes do
  def get_string(struct, pos, len, encoding) do
    if (encoding == nil) do
      encoding = {:utf8}
    end
    if (pos < 0 or len < 0 or pos + len > length(struct)) do
      throw("Out of bounds")
    end
    slice = :binary.part(struct.b, pos, len)
    :unicode.characters_to_list(slice, :utf8)
  end
  def to_string(struct) do
    :unicode.characters_to_list(struct, :utf8)
  end
  def get(struct, pos) do
    if (pos < 0 or pos >= length(struct)) do
      throw("Out of bounds")
    end
    :binary.at(struct.b, pos)
  end
  def set(struct, pos, v) do
    if (pos < 0 or pos >= length(struct)) do
      throw("Out of bounds")
    end
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(struct.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos < (length(struct) - 1)) do
      temp_var1 = :binary.part(struct.b, pos + 1, ((struct.length - pos) - 1))
    else
      temp_var1 = <<>>
    end
    b = <<temp_var::binary, v::8, temp_var1::binary>>
  end
  def blit(struct, pos, src, srcpos, len) do
    if (pos < 0 or srcpos < 0 or len < 0 or pos + len > length(struct) or srcpos + len > length(src)) do
      throw("Out of bounds")
    end
    src_slice = :binary.part(src.b, srcpos, len)
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(struct.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos + len < length(struct)) do
      temp_var1 = :binary.part(struct.b, pos + len, ((struct.length - pos) - len))
    else
      temp_var1 = <<>>
    end
    b = <<temp_var::binary, src_slice::binary, temp_var1::binary>>
  end
  def sub(struct, pos, len) do
    if (pos < 0 or len < 0 or pos + len > length(struct)) do
      throw("Out of bounds")
    end
    sub_binary = :binary.part(struct.b, pos, len)
    Bytes.new(len, sub_binary)
  end
  def fill(struct, pos, len, value) do
    if (pos < 0 or len < 0 or pos + len > length(struct)) do
      throw("Out of bounds")
    end
    fill_bytes = :binary.copy(<<value::8>>, len)
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(struct.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos + len < length(struct)) do
      temp_var1 = :binary.part(struct.b, pos + len, ((struct.length - pos) - len))
    else
      temp_var1 = <<>>
    end
    b = <<temp_var::binary, fill_bytes::binary, temp_var1::binary>>
  end
  def compare(struct, other) do
    case struct.b do
            x when x < other.b -> -1
            x when x > other.b -> 1
            _ -> 0
        end
  end
  def get_data(struct) do
    struct.b
  end
  def get_double(struct, pos) do
    if (pos < 0 or pos + 8 > length(struct)) do
      throw("Out of bounds")
    end
    <<value::float-little-size(64)>> = :binary.part(struct.b, pos, 8); value
  end
  def set_double(struct, pos, v) do
    if (pos < 0 or pos + 8 > length(struct)) do
      throw("Out of bounds")
    end
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(struct.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos + 8 < length(struct)) do
      temp_var1 = :binary.part(struct.b, pos + 8, ((struct.length - pos) - 8))
    else
      temp_var1 = <<>>
    end
    b = <<temp_var::binary, v::float-little-size(64), temp_var1::binary>>
  end
  def get_float(struct, pos) do
    if (pos < 0 or pos + 4 > length(struct)) do
      throw("Out of bounds")
    end
    <<value::float-little-size(32)>> = :binary.part(struct.b, pos, 4); value
  end
  def set_float(struct, pos, v) do
    if (pos < 0 or pos + 4 > length(struct)) do
      throw("Out of bounds")
    end
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(struct.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos + 4 < length(struct)) do
      temp_var1 = :binary.part(struct.b, pos + 4, ((struct.length - pos) - 4))
    else
      temp_var1 = <<>>
    end
    b = <<temp_var::binary, v::float-little-size(32), temp_var1::binary>>
  end
  def get_u_int16(struct, pos) do
    if (pos < 0 or pos + 2 > length(struct)) do
      throw("Out of bounds")
    end
    <<value::little-unsigned-size(16)>> = :binary.part(struct.b, pos, 2); value
  end
  def set_u_int16(struct, pos, v) do
    if (pos < 0 or pos + 2 > length(struct)) do
      throw("Out of bounds")
    end
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(struct.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos + 2 < length(struct)) do
      temp_var1 = :binary.part(struct.b, pos + 2, ((struct.length - pos) - 2))
    else
      temp_var1 = <<>>
    end
    b = <<temp_var::binary, v::little-unsigned-size(16), temp_var1::binary>>
  end
  def get_int32(struct, pos) do
    if (pos < 0 or pos + 4 > length(struct)) do
      throw("Out of bounds")
    end
    <<value::little-signed-size(32)>> = :binary.part(struct.b, pos, 4); value
  end
  def set_int32(struct, pos, v) do
    if (pos < 0 or pos + 4 > length(struct)) do
      throw("Out of bounds")
    end
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(struct.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos + 4 < length(struct)) do
      temp_var1 = :binary.part(struct.b, pos + 4, ((struct.length - pos) - 4))
    else
      temp_var1 = <<>>
    end
    b = <<temp_var::binary, v::little-signed-size(32), temp_var1::binary>>
  end
  def get_int64(struct, pos) do
    if (pos < 0 or pos + 8 > length(struct)) do
      throw("Out of bounds")
    end
    <<value::little-signed-size(64)>> = :binary.part(struct.b, pos, 8); value
  end
  def set_int64(struct, pos, v) do
    if (pos < 0 or pos + 8 > length(struct)) do
      throw("Out of bounds")
    end
    temp_var = nil
    if (pos > 0) do
      temp_var = :binary.part(struct.b, 0, pos)
    else
      temp_var = <<>>
    end
    temp_var1 = nil
    if (pos + 8 < length(struct)) do
      temp_var1 = :binary.part(struct.b, pos + 8, ((struct.length - pos) - 8))
    else
      temp_var1 = <<>>
    end
    b = <<temp_var::binary, v::little-signed-size(64), temp_var1::binary>>
  end
  def read_string(struct, pos, len) do
    :unicode.characters_to_list(struct, :utf8)
  end
  def to_hex(struct) do
    Base.encode16(struct.b, case: :lower)
  end
  def alloc(length) do
    Bytes.new(length, (:binary.copy(<<0>>, length)))
  end
  def of_string(s, encoding) do
    binary = :unicode.characters_to_binary(s, :utf8)
    length2 = byte_size(binary)
    Bytes.new(length2, binary)
  end
  def fast_get(b, pos) do
    :binary.at(b, pos)
  end
  def of_hex(s) do
    binary = Base.decode16!(s, case: :mixed)
    length2 = byte_size(binary)
    Bytes.new(length2, binary)
  end
  def of_data(b) do
    Bytes.new((byte_size(b)), b)
  end
end