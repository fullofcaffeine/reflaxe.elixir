defmodule Bytes do
  defp new(length, b) do
    %{:length => length, :b => b}
  end
  def get_string(struct, pos, len, encoding) do
    if (encoding == nil) do
      encoding = :utf8
    end
    if (pos < 0 || len < 0 || pos + len > struct.length) do
      throw("Out of bounds")
    end
    slice = :binary.part(struct.b, pos, len)
    :unicode.characters_to_list(slice, :utf8)
  end
  def to_string(struct) do
    :unicode.characters_to_list(struct, :utf8)
  end
  def get(struct, pos) do
    if (pos < 0 || pos >= struct.length) do
      throw("Out of bounds")
    end
    :binary.at(struct.b, pos)
  end
  def set(struct, pos, v) do
    if (pos < 0 || pos >= struct.length) do
      throw("Out of bounds")
    end
    before_part = if (pos > 0) do
  :binary.part(struct.b, 0, pos)
else
  <<>>
end
    after_part = if (pos < (struct.length - 1)) do
  :binary.part(struct.b, pos + 1, ((struct.length - pos) - 1))
else
  <<>>
end
    b = <<before_part::binary, v::8, after_part::binary>>
  end
  def blit(struct, pos, src, srcpos, len) do
    if (pos < 0 || srcpos < 0 || len < 0 || pos + len > struct.length || srcpos + len > src.length) do
      throw("Out of bounds")
    end
    src_slice = :binary.part(src.b, srcpos, len)
    before_part = if (pos > 0) do
  :binary.part(struct.b, 0, pos)
else
  <<>>
end
    after_part = if (pos + len < struct.length) do
  :binary.part(struct.b, pos + len, ((struct.length - pos) - len))
else
  <<>>
end
    b = <<before_part::binary, src_slice::binary, after_part::binary>>
  end
  def sub(struct, pos, len) do
    if (pos < 0 || len < 0 || pos + len > struct.length) do
      throw("Out of bounds")
    end
    sub_binary = Bytes.new(len, :binary.part(struct.b, pos, len))
  end
  def fill(struct, pos, len, value) do
    if (pos < 0 || len < 0 || pos + len > struct.length) do
      throw("Out of bounds")
    end
    fill_bytes = :binary.copy(<<value::8>>, len)
    before_part = if (pos > 0) do
  :binary.part(struct.b, 0, pos)
else
  <<>>
end
    after_part = if (pos + len < struct.length) do
  :binary.part(struct.b, pos + len, ((struct.length - pos) - len))
else
  <<>>
end
    b = <<before_part::binary, fill_bytes::binary, after_part::binary>>
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
    if (pos < 0 || pos + 8 > struct.length) do
      throw("Out of bounds")
    end
    <<value::float-little-size(64)>> = :binary.part(struct.b, pos, 8); value
  end
  def set_double(struct, pos, v) do
    if (pos < 0 || pos + 8 > struct.length) do
      throw("Out of bounds")
    end
    before_part = if (pos > 0) do
  :binary.part(struct.b, 0, pos)
else
  <<>>
end
    after_part = if (pos + 8 < struct.length) do
  :binary.part(struct.b, pos + 8, ((struct.length - pos) - 8))
else
  <<>>
end
    b = <<before_part::binary, v::float-little-size(64), after_part::binary>>
  end
  def get_float(struct, pos) do
    if (pos < 0 || pos + 4 > struct.length) do
      throw("Out of bounds")
    end
    <<value::float-little-size(32)>> = :binary.part(struct.b, pos, 4); value
  end
  def set_float(struct, pos, v) do
    if (pos < 0 || pos + 4 > struct.length) do
      throw("Out of bounds")
    end
    before_part = if (pos > 0) do
  :binary.part(struct.b, 0, pos)
else
  <<>>
end
    after_part = if (pos + 4 < struct.length) do
  :binary.part(struct.b, pos + 4, ((struct.length - pos) - 4))
else
  <<>>
end
    b = <<before_part::binary, v::float-little-size(32), after_part::binary>>
  end
  def get_u_int16(struct, pos) do
    if (pos < 0 || pos + 2 > struct.length) do
      throw("Out of bounds")
    end
    <<value::little-unsigned-size(16)>> = :binary.part(struct.b, pos, 2); value
  end
  def set_u_int16(struct, pos, v) do
    if (pos < 0 || pos + 2 > struct.length) do
      throw("Out of bounds")
    end
    before_part = if (pos > 0) do
  :binary.part(struct.b, 0, pos)
else
  <<>>
end
    after_part = if (pos + 2 < struct.length) do
  :binary.part(struct.b, pos + 2, ((struct.length - pos) - 2))
else
  <<>>
end
    b = <<before_part::binary, v::little-unsigned-size(16), after_part::binary>>
  end
  def get_int32(struct, pos) do
    if (pos < 0 || pos + 4 > struct.length) do
      throw("Out of bounds")
    end
    <<value::little-signed-size(32)>> = :binary.part(struct.b, pos, 4); value
  end
  def set_int32(struct, pos, v) do
    if (pos < 0 || pos + 4 > struct.length) do
      throw("Out of bounds")
    end
    before_part = if (pos > 0) do
  :binary.part(struct.b, 0, pos)
else
  <<>>
end
    after_part = if (pos + 4 < struct.length) do
  :binary.part(struct.b, pos + 4, ((struct.length - pos) - 4))
else
  <<>>
end
    b = <<before_part::binary, v::little-signed-size(32), after_part::binary>>
  end
  def get_int64(struct, pos) do
    if (pos < 0 || pos + 8 > struct.length) do
      throw("Out of bounds")
    end
    <<value::little-signed-size(64)>> = :binary.part(struct.b, pos, 8); value
  end
  def set_int64(struct, pos, v) do
    if (pos < 0 || pos + 8 > struct.length) do
      throw("Out of bounds")
    end
    before_part = if (pos > 0) do
  :binary.part(struct.b, 0, pos)
else
  <<>>
end
    after_part = if (pos + 8 < struct.length) do
  :binary.part(struct.b, pos + 8, ((struct.length - pos) - 8))
else
  <<>>
end
    b = <<before_part::binary, v::little-signed-size(64), after_part::binary>>
  end
  def read_string(struct, pos, len) do
    :unicode.characters_to_list(struct, :utf8)
  end
  def to_hex(struct) do
    Base.encode16(struct.b, case: :lower)
  end
  def alloc(length) do
    b = Bytes.new(length, :binary.copy(<<0>>, length))
  end
  def of_string(s, encoding) do
    if (encoding == nil) do
      encoding = :utf8
    end
    binary = :unicode.characters_to_binary(s, :utf8)
    length = Bytes.new(byte_size(binary), binary)
  end
  def of_hex(s) do
    binary = Base.decode16!(s, case: :mixed)
    length = Bytes.new(byte_size(binary), binary)
  end
  def of_data(b) do
    length = Bytes.new(byte_size(b), b)
  end
end