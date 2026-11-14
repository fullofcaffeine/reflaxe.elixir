defmodule Main do
  def main() do

  end
  defp step(n, fail_at) do
    if (n == fail_at), do: {:err, "stopped at " <> Reflaxe.Elixir.HaxeFloat.to_string(n)}, else: {:ok, n + 1}
  end
  def chain(start, fail_at) do
    (case step(start, fail_at) do
      {:ok, value} ->
        a1 = value
        (case step(a1, fail_at) do
          {:ok, value} ->
            a2 = value
            (case step(a2, fail_at) do
              {:ok, value} ->
                a3 = value
                (case step(a3, fail_at) do
                  {:ok, value} ->
                    a4 = value
                    (case step(a4, fail_at) do
                      {:ok, value} ->
                        a5 = value
                        (case step(a5, fail_at) do
                          {:ok, value} ->
                            a6 = value
                            (case step(a6, fail_at) do
                              {:ok, value} ->
                                a7 = value
                                (case step(a7, fail_at) do
                                  {:ok, value} ->
                                    a8 = value
                                    (case step(a8, fail_at) do
                                      {:ok, value} ->
                                        a9 = value
                                        (case step(a9, fail_at) do
                                          {:ok, value} ->
                                            a10 = value
                                            (case step(a10, fail_at) do
                                              {:ok, value} ->
                                                a11 = value
                                                (case step(a11, fail_at) do
                                                  {:ok, value} ->
                                                    a12 = value
                                                    {:ok, a12}
                                                  {:err, error} -> {:err, error}
                                                end)
                                              {:err, error} -> {:err, error}
                                            end)
                                          {:err, error} -> {:err, error}
                                        end)
                                      {:err, error} -> {:err, error}
                                    end)
                                  {:err, error} -> {:err, error}
                                end)
                              {:err, error} -> {:err, error}
                            end)
                          {:err, error} -> {:err, error}
                        end)
                      {:err, error} -> {:err, error}
                    end)
                  {:err, error} -> {:err, error}
                end)
              {:err, error} -> {:err, error}
            end)
          {:err, error} -> {:err, error}
        end)
      {:err, error} -> {:err, error}
    end)
  end
end
