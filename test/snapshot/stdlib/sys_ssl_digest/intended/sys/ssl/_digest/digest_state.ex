defmodule DigestState do
  def sign(data, private_key, algorithm) do
    :public_key.sign(data, algorithm, private_key)
  end
  def verify(data, signature, public_key, algorithm) do
    :public_key.verify(data, algorithm, signature, public_key)
  end
end
