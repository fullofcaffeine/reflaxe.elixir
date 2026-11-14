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
                                                    (case step(a12, fail_at) do
                                                      {:ok, value} ->
                                                        a13 = value
                                                        (case step(a13, fail_at) do
                                                          {:ok, value} ->
                                                            a14 = value
                                                            (case step(a14, fail_at) do
                                                              {:ok, value} ->
                                                                a15 = value
                                                                (case step(a15, fail_at) do
                                                                  {:ok, value} ->
                                                                    a16 = value
                                                                    (case step(a16, fail_at) do
                                                                      {:ok, value} ->
                                                                        a17 = value
                                                                        (case step(a17, fail_at) do
                                                                          {:ok, value} ->
                                                                            a18 = value
                                                                            (case step(a18, fail_at) do
                                                                              {:ok, value} ->
                                                                                a19 = value
                                                                                (case step(a19, fail_at) do
                                                                                  {:ok, value} ->
                                                                                    a20 = value
                                                                                    (case step(a20, fail_at) do
                                                                                      {:ok, value} ->
                                                                                        a21 = value
                                                                                        (case step(a21, fail_at) do
                                                                                          {:ok, value} ->
                                                                                            a22 = value
                                                                                            (case step(a22, fail_at) do
                                                                                              {:ok, value} ->
                                                                                                a23 = value
                                                                                                (case step(a23, fail_at) do
                                                                                                  {:ok, value} ->
                                                                                                    a24 = value
                                                                                                    {:ok, a24}
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
