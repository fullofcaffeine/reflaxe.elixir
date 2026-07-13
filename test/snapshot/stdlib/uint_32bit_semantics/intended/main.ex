defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    all_ones = -1
    wrapped_add = (
          case Bitwise.band(all_ones + 1, 0xFFFFFFFF) do
            v when v >= 0x80000000 -> v - 0x100000000
            v -> v
          end
    )
    assert_that(wrapped_add == 0, "UInt wrap-around add failed")
    wrapped_mul = (
          case Bitwise.band(all_ones * 2, 0xFFFFFFFF) do
            v when v >= 0x80000000 -> v - 0x100000000
            v -> v
          end
    )
    assert_that(wrapped_mul == -2, "UInt wrap-around mul failed")
    shifted = (
          case Bitwise.band(Bitwise.bsr(Bitwise.band(all_ones, 0xFFFFFFFF), Bitwise.band(1, 31)), 0xFFFFFFFF) do
            v when v >= 0x80000000 -> v - 0x100000000
            v -> v
          end
    )
    assert_that(shifted == 2147483647, "UInt unsigned shift-right failed")
    assert_that((fn ->
        a_neg = all_ones < 0
        b_neg = false
        if (a_neg != b_neg), do: a_neg, else: all_ones > 1
      end).(), "UInt unsigned comparison failed (0xFFFFFFFF > 1)")
    assert_that((fn ->
        a_neg = false
        b_neg = all_ones < 0
        not if (a_neg != b_neg), do: a_neg, else: 1 > all_ones
      end).(), "UInt unsigned comparison failed (1 !> 0xFFFFFFFF)")
    zero = 0
    not_zero = (
          case Bitwise.band(Bitwise.bnot(zero), 0xFFFFFFFF) do
            v when v >= 0x80000000 -> v - 0x100000000
            v -> v
          end
    )
    assert_that(not_zero == -1, "UInt bitwise not failed (~0)")
    ten = 10
    five = 5
    assert_that((fn ->
        a = (
              case Bitwise.band(rem(Bitwise.band(all_ones, 0xFFFFFFFF), Bitwise.band(ten, 0xFFFFFFFF)), 0xFFFFFFFF) do
                v when v >= 0x80000000 -> v - 0x100000000
                v -> v
              end
        )
        a == five
      end).(), "UInt modulo failed (0xFFFFFFFF % 10 == 5)")
  end
end
