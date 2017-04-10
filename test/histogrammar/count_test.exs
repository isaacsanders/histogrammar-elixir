defmodule Histogrammar.CountTest do
  use ExUnit.Case, async: false
  use Quixir
  alias Histogrammar.Count

  doctest Histogrammar.Count

  def uniform_present_tense(xs) do
    Enum.reduce(xs, Count.ing(), fn
      (x, counting) ->
        Histogrammar.fill(counting, x, 1.0)
    end)
  end

  def random_present_tense(weights) do
    Enum.reduce(weights, Count.ing(), fn
      (weight, counting) ->
        Histogrammar.fill(counting, weight, weight)
    end)
  end

  test :fill_constantly_weighted do
    ptest xs: list(of: int()) do
      counting = uniform_present_tense(xs)
      assert counting.entries == length(xs)
    end
  end

  test :fill_randomly_weighted do
    ptest weights: list(of: int()) do
      counting = random_present_tense(weights)
      assert Enum.reduce(weights, 0.0, fn
        (weight, sum) ->
          if weight > 0.0, do: sum + weight, else: sum
      end) == counting.entries
    end
  end

  test :past_tense_combine do
    ptest a: int(), b: int() do
      x = Count.ed(a)
      y = Count.ed(b)
      z = Histogrammar.combine(x, y)
      assert z.entries == a + b
    end
  end

  test :uniform_present_tense_combine do
    ptest a: list(of: int()), b: list(of: int()) do
      x = uniform_present_tense(a)
      y = uniform_present_tense(b)
      z = Histogrammar.combine(x, y)
      assert z.entries == (length(a) + length(b))
    end
  end

  test :mixed_present_tense_combine do
    ptest a: list(of: int()), b: list(of: int()) do
      x = uniform_present_tense(a)
      y = random_present_tense(b)
      z = Histogrammar.combine(x, y)
      assert z.entries == (length(a) +
       Enum.reduce(b, 0.0, &(if &1 > 0.0, do: &1 + &2, else: &2)))
    end
  end

  test :random_present_tense_combine do
    ptest a: list(of: int()), b: list(of: int()) do
      x = random_present_tense(a)
      y = random_present_tense(b)
      z = Histogrammar.combine(x, y)
      first = Enum.reduce(a, 0.0, &(if &1 > 0.0, do: &1 + &2, else: &2))
      second = Enum.reduce(b, 0.0, &(if &1 > 0.0, do: &1 + &2, else: &2))
      assert z.entries == (first + second)
    end
  end

  test :mixed_tense_combine do
    ptest weights: list(of: int()), b: int() do
      x = uniform_present_tense(weights)
      y = Count.ed(b)
      z = Histogrammar.combine(x, y)
      assert z.entries == b + x.entries
    end
  end

  test :transforming_fill do
    ptest weights: list(of: int()) do
      transform = fn (x) -> x * x end
      counting = Enum.reduce(weights, Count.ing(transform), fn (weight, counting) ->
        Histogrammar.fill(counting, weight, weight)
      end)
      sum_of_squares = Enum.reduce(weights, 0.0, &(if &1 > 0.0, do: transform.(&1) + &2, else: &2))
      assert assert counting.entries == sum_of_squares
    end
  end

  test :present_tense_encoding do
    ptest weights: list(of: int()) do
      counting = Enum.into(weights, Count.ing())
      assert Poison.encode!(counting) == ~s({"version":"1.0","type":"Count","data":#{length(weights) * 1.0}})
    end
  end

  test :past_tense_encoding do
    ptest entries: int() do
      counted = Count.ed(abs(entries))
      assert Poison.encode!(counted) == ~s({"version":"1.0","type":"Count","data":#{abs(entries)}})
    end
  end
end
