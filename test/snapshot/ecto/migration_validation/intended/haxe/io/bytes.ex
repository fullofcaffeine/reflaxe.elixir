defmodule Bytes do
  import Kernel, except: [to_string: 1], warn: false
  defp new(length_param, b_param) do
    struct = %{:length => nil, :b => nil}
    struct = %{struct | length: length_param}
    struct = %{struct | b: b_param}
    struct
  end
  def get_string(struct, pos, len, _) do
    if (pos < 0 or len < 0 or pos + len > length(struct)) do
      throw("Out of bounds")
    end
    slice = :binary.part(struct.b, pos, len)
    :unicode.characters_to_list(slice, :utf8)
  end
  def to_string(struct) do
    get_string(struct, 0, length(struct), nil)
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
    before_part = if (pos > 0) do
      :binary.part(struct.b, 0, pos)
    else
      <<>>
    end
    after_part = if (pos < (length(struct) - 1)) do
      :binary.part(struct.b, pos + 1, ((length(struct) - pos) - 1))
    else
      <<>>
    end
    struct = %{struct | b: <<before_part::binary, v::8, after_part::binary>>}
    struct
  end
  def blit(struct, pos, src, srcpos, len) do
    if (pos < 0 or srcpos < 0 or len < 0 or pos + len > length(struct) or srcpos + len > length(src)) do
      throw("Out of bounds")
    end
    src_slice = :binary.part(src.b, srcpos, len)
    before_part = if (pos > 0) do
      :binary.part(struct.b, 0, pos)
    else
      <<>>
    end
    after_part = if (pos + len < length(struct)) do
      :binary.part(struct.b, pos + len, ((length(struct) - pos) - len))
    else
      <<>>
    end
    struct = %{struct | b: <<before_part::binary, src_slice::binary, after_part::binary>>}
    struct
  end
  def sub(struct, pos, len) do
    if (pos < 0 or len < 0 or pos + len > length(struct)) do
      throw("Out of bounds")
    end
    sub_binary = :binary.part(struct.b, pos, len)
    _ = new(len, sub_binary)
  end
  def fill(struct, pos, len, value) do
    if (pos < 0 or len < 0 or pos + len > length(struct)) do
      throw("Out of bounds")
    end
    fill_bytes = :binary.copy(<<value::8>>, len)
    before_part = if (pos > 0) do
      :binary.part(struct.b, 0, pos)
    else
      <<>>
    end
    after_part = if (pos + len < length(struct)) do
      :binary.part(struct.b, pos + len, ((length(struct) - pos) - len))
    else
      <<>>
    end
    struct = %{struct | b: <<before_part::binary, fill_bytes::binary, after_part::binary>>}
    struct
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
    before_part = if (pos > 0) do
      :binary.part(struct.b, 0, pos)
    else
      <<>>
    end
    after_part = if (pos + 8 < length(struct)) do
      :binary.part(struct.b, pos + 8, ((length(struct) - pos) - 8))
    else
      <<>>
    end
    struct = %{struct | b: <<before_part::binary, v::float-little-size(64), after_part::binary>>}
    struct
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
    before_part = if (pos > 0) do
      :binary.part(struct.b, 0, pos)
    else
      <<>>
    end
    after_part = if (pos + 4 < length(struct)) do
      :binary.part(struct.b, pos + 4, ((length(struct) - pos) - 4))
    else
      <<>>
    end
    struct = %{struct | b: <<before_part::binary, v::float-little-size(32), after_part::binary>>}
    struct
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
    before_part = if (pos > 0) do
      :binary.part(struct.b, 0, pos)
    else
      <<>>
    end
    after_part = if (pos + 2 < length(struct)) do
      :binary.part(struct.b, pos + 2, ((length(struct) - pos) - 2))
    else
      <<>>
    end
    struct = %{struct | b: <<before_part::binary, v::little-unsigned-size(16), after_part::binary>>}
    struct
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
    before_part = if (pos > 0) do
      :binary.part(struct.b, 0, pos)
    else
      <<>>
    end
    after_part = if (pos + 4 < length(struct)) do
      :binary.part(struct.b, pos + 4, ((length(struct) - pos) - 4))
    else
      <<>>
    end
    struct = %{struct | b: <<before_part::binary, v::little-signed-size(32), after_part::binary>>}
    struct
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
    before_part = if (pos > 0) do
      :binary.part(struct.b, 0, pos)
    else
      <<>>
    end
    after_part = if (pos + 8 < length(struct)) do
      :binary.part(struct.b, pos + 8, ((length(struct) - pos) - 8))
    else
      <<>>
    end
    struct = %{struct | b: <<before_part::binary, v::little-signed-size(64), after_part::binary>>}
    struct
  end
  def read_string(struct, pos, len) do
    get_string(struct, pos, len, nil)
  end
  def to_hex(struct) do
    Base.encode16(struct.b, case: :lower)
  end
  def alloc(length_param) do
    b = :binary.copy(<<0>>, length_param)
    _ = new(length_param, b)
  end
  def of_string(s, _) do
    binary = :unicode.characters_to_binary(s, :utf8)
    length = byte_size(binary)
    _ = new(length, binary)
  end
  def fast_get(b_param, pos) do
    :binary.at(b_param, pos)
  end
  def of_hex(s) do
    binary = Base.decode16!(s, case: :mixed)
    length = byte_size(binary)
    _ = new(length, binary)
  end
  def of_data(b_param) do
    length = byte_size(b_param)
    _ = new(length, b_param)
  end
end
