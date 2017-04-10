defmodule Histogrammar.SumTest do
  use ExUnit.Case, async: false
  use Quixir
  alias Histogrammar.Sum
  alias Histogrammar.Util

  doctest Histogrammar.Sum

  def uniform_present_tense(xs) do
    Enum.into(xs, Sum.ing(&Util.identity/1))
  end

  def randomly_weighted_present_tense(weights) do
    Enum.reduce(weights, Sum.ing(&Util.identity/1), fn
      (weight, summing) ->
        Histogrammar.fill(summing, weight, weight)
    end)
  end

  test :fill_constantly_weighted do
    ptest xs: list(of: int()) do
      summing = uniform_present_tense(xs)
      sum = Enum.reduce(xs, 0.0, fn
        (weight, sum) ->
          sum + weight
      end)
      assert summing.entries == length(xs) and sum == summing.sum
    end
  end

  test :fill_randomly_weighted do
    ptest weights: list(of: int()) do
      summing = randomly_weighted_present_tense(weights)
      sum = Enum.reduce(weights, 0.0, fn
        (weight, sum) ->
          if weight > 0.0, do: sum + weight, else: sum
      end)
      assert summing.entries == sum and sum == summing.sum
    end
  end

  test :past_tense_combine do
    ptest a: int(), b: int() do
      x = Sum.ed(a, a)
      y = Sum.ed(b, b)
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
      y = randomly_weighted_present_tense(b)
      z = Histogrammar.combine(x, y)
      assert z.entries == (length(a) +
       Enum.reduce(b, 0.0, &(if &1 > 0.0, do: &1 + &2, else: &2)))
    end
  end

  test :random_present_tense_combine do
    ptest a: list(of: int()), b: list(of: int()) do
      x = randomly_weighted_present_tense(a)
      y = randomly_weighted_present_tense(b)
      z = Histogrammar.combine(x, y)
      first = Enum.reduce(a, 0.0, &(if &1 > 0.0, do: &1 + &2, else: &2))
      second = Enum.reduce(b, 0.0, &(if &1 > 0.0, do: &1 + &2, else: &2))
      assert z.entries == (first + second)
      assert z.sum == (first + second)
    end
  end

  test :mixed_tense_combine do
    ptest weights: list(of: int()), b: int() do
      x = uniform_present_tense(weights)
      y = Sum.ed(b, b)
      z = Histogrammar.combine(x, y)
      assert z.entries == b + x.entries
    end
  end

  test :transforming_fill do
    ptest weights: list(of: int()) do
      transform = fn (x) -> x * x end
      summing = Enum.into(weights, Sum.ing(transform))
      sum_of_squares = Enum.reduce(weights, 0.0, &(transform.(&1) + &2))
      assert summing.sum == sum_of_squares
    end
  end

  test :present_tense_encoding do
    ptest weights: list(of: int()) do
      summing = uniform_present_tense(weights)
      actual = Poison.encode!(summing) |> Poison.decode!(keys: :atoms)
      assert actual.data == Histogrammar.encoder_data(summing)
    end
  end

  test :named_present_tense_encoding do
    ptest weights: list(of: int()) do
      summing = Enum.into(weights, Sum.ing(&Util.identity/1, "myfunc"))
      actual = Poison.encode!(summing) |> Poison.decode!(keys: :atoms)
      assert actual.data == Histogrammar.encoder_data(summing)
    end
  end

  test :past_tense_encoding do
    ptest entries: int() do
      summed = Sum.ed(abs(entries), entries)
      actual = Poison.encode!(summed) |> Poison.decode!(keys: :atoms)
      assert actual.data == Histogrammar.encoder_data(summed)
    end
  end

  test :named_past_tense_encoding do
    ptest entries: float(min: 0.0) do
      summed = Sum.ed(abs(entries), entries, "myfunc")
      actual = Poison.encode!(summed) |> Poison.decode!(keys: :atoms)
      assert actual.data == Histogrammar.encoder_data(summed)
    end
  end
end
