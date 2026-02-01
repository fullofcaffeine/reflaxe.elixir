package haxe;

import StringTools;

/**
 * Int64Helper (Elixir target)
 *
 * Helper for parsing to `Int64` instances.
 *
 * Kept close to the reference algorithm so overflow/underflow behavior is deterministic.
 */
class Int64Helper {
    public static function parseString(sParam: String): Int64 {
        #if (!macro && elixir_output)
        var parsed: Int = untyped __elixir__(
            "s = String.trim({0})\ncase Integer.parse(s) do\n  {i, \"\"} ->\n    if i < -9223372036854775808 or i > 9223372036854775807 do\n      raise Reflaxe.Elixir.HaxeThrow, [value: \"NumberFormatError\"]\n    else\n      i\n    end\n  _ -> raise Reflaxe.Elixir.HaxeThrow, [value: \"NumberFormatError\"]\nend",
            sParam
        );
        return cast parsed;
        #else
        var base = Int64.ofInt(10);
        var current = Int64.ofInt(0);
        var multiplier = Int64.ofInt(1);
        var isNegative = false;

        var s = StringTools.trim(sParam);
        if (s.charAt(0) == "-") {
            isNegative = true;
            s = s.substring(1, s.length);
        }

        var len = s.length;
        for (i in 0...len) {
            var digitInt = s.charCodeAt(len - 1 - i) - "0".code;
            if (digitInt < 0 || digitInt > 9) {
                throw "NumberFormatError";
            }

            if (digitInt != 0) {
                var digit: Int64 = Int64.ofInt(digitInt);
                if (isNegative) {
                    current = Int64.sub(current, Int64.mul(multiplier, digit));
                    if (!Int64.isNeg(current)) {
                        throw "NumberFormatError: Underflow";
                    }
                } else {
                    current = Int64.add(current, Int64.mul(multiplier, digit));
                    if (Int64.isNeg(current)) {
                        throw "NumberFormatError: Overflow";
                    }
                }
            }

            multiplier = Int64.mul(multiplier, base);
        }

        return current;
        #end
    }

    public static function fromFloat(f: Float): Int64 {
        if (Math.isNaN(f) || !Math.isFinite(f)) {
            throw "Number is NaN or Infinite";
        }

        var noFractions = f - (f % 1);

        // 2^53-1 and -2^53+1 are parseable without precision loss.
        if (noFractions > 9007199254740991) throw "Conversion overflow";
        if (noFractions < -9007199254740991) throw "Conversion underflow";

        var result = Int64.ofInt(0);
        var neg = noFractions < 0;
        var rest = neg ? -noFractions : noFractions;

        var i = 0;
        while (rest >= 1) {
            var curr = rest % 2;
            rest = rest / 2;
            if (curr >= 1) {
                result = Int64.add(result, Int64.shl(Int64.ofInt(1), i));
            }
            i++;
        }

        return neg ? Int64.neg(result) : result;
    }
}
