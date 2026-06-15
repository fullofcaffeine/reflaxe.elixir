defmodule StringInput do
  def new(source) do
    struct = %{:__reflaxe_class__ => StringInput, :data => nil, :total_length => nil, :ref_id => nil, :dict_key => nil, :position => nil, :length => nil, :big_endian => nil}
    struct = Map.merge(struct, Map.drop(BytesInput.new(Bytes.of_string(source, nil), nil, nil), [:__struct__, :__reflaxe_class__]))
    struct
  end
  def get_position(struct) do
    BytesInput.get_position(struct)
  end
  def get_length(struct) do
    BytesInput.get_length(struct)
  end
  def set_position(struct, p) do
    BytesInput.set_position(struct, p)
  end
  def read_byte(struct) do
    BytesInput.read_byte(struct)
  end
  def read_bytes(struct, buf, pos, len) do
    BytesInput.read_bytes(struct, buf, pos, len)
  end
  def read_all(struct, bufsize) do
    BytesInput.read_all(struct, bufsize)
  end
  def read_line(struct) do
    BytesInput.read_line(struct)
  end
  def close(struct) do
    BytesInput.close(struct)
  end
end
