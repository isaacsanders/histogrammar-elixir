defmodule Histogrammar.SumTest do
  use ExUnit.Case, async: false
  use ExCheck
  alias Histogrammar.Sum
  alias Histogrammar.Util

  doctest Histogrammar.Sum

  def uniform_present_tense(xs) do
    Enum.into(xs, Sum.ing(&Util.identity/1))
  end

  def randomly_weighted_present_tense(weights) do
    Enum.reduce(weights, Sum.ing(&Util.identity/1), fn
      (weight, summing) ->
        Sum.fill(summing, weight, weight)
    end)
  end

  property :fill_constantly_weighted do
    for_all xs in list(int()) do
      summing = uniform_present_tense(xs)
      sum = Enum.reduce(xs, 0.0, fn
        (weight, sum) ->
          sum + weight
      end)
      summing.entries == length(xs) and sum == summing.sum
    end
  end

  property :fill_randomly_weighted do
    for_all weights in list(int()) do
      summing = randomly_weighted_present_tense(weights)
      sum = Enum.reduce(weights, 0.0, fn
        (weight, sum) ->
          if weight > 0.0, do: sum + weight, else: sum
      end)
      summing.entries == sum and sum == summing.sum
    end
  end

  property :past_tense_combine do
    for_all {a, b} in {int(), int()} do
      x = Sum.ed(a, a)
      y = Sum.ed(b, b)
      z = Sum.combine(x, y)
      z.entries == a + b
    end
  end

  property :uniform_present_tense_combine do
    for_all {a, b} in {list(int()), list(int())} do
      x = uniform_present_tense(a)
      y = uniform_present_tense(b)
      z = Sum.combine(x, y)
      z.entries == (length(a) + length(b))
    end
  end

  property :mixed_present_tense_combine do
    for_all {a, b} in {list(int()), list(int())} do
      x = uniform_present_tense(a)
      y = randomly_weighted_present_tense(b)
      z = Sum.combine(x, y)
      z.entries == (length(a) +
       Enum.reduce(b, 0.0, &(if &1 > 0.0, do: &1 + &2, else: &2)))
    end
  end

  property :random_present_tense_combine do
    for_all {a, b} in {list(int()), list(int())} do
      x = randomly_weighted_present_tense(a)
      y = randomly_weighted_present_tense(b)
      z = Sum.combine(x, y)
      first = Enum.reduce(a, 0.0, &(if &1 > 0.0, do: &1 + &2, else: &2))
      second = Enum.reduce(b, 0.0, &(if &1 > 0.0, do: &1 + &2, else: &2))
      z.entries == (first + second) &&
      z.sum == (first + second)
    end
  end

  property :mixed_tense_combine do
    for_all {weights, b} in {list(int()), int()} do
      x = uniform_present_tense(weights)
      y = Sum.ed(b, b)
      z = Sum.combine(x, y)
      z.entries == b + x.entries
    end
  end

  property :transforming_fill do
    for_all weights in list(int()) do
      transform = fn (x) -> x * x end
      summing = Enum.into(weights, Sum.ing(transform))
      sum_of_squares = Enum.reduce(weights, 0.0, &(transform.(&1) + &2))
      summing.sum == sum_of_squares
    end
  end

  property :present_tense_encoding do
    for_all weights in list(int()) do
      summing = uniform_present_tense(weights)
      actual = Poison.encode!(summing) |> Poison.decode!(keys: :atoms)
      actual.data == Sum.encoder_data(summing)
    end
  end

  property :named_present_tense_encoding do
    for_all weights in list(int()) do
      summing = Enum.into(weights, Sum.ing(&Util.identity/1, "myfunc"))
      actual = Poison.encode!(summing) |> Poison.decode!(keys: :atoms)
      actual.data == Sum.encoder_data(summing)
    end
  end

  property :past_tense_encoding do
    for_all entries in int() do
      summed = Sum.ed(abs(entries), entries)
      actual = Poison.encode!(summed) |> Poison.decode!(keys: :atoms)
      actual.data == Sum.encoder_data(summed)
    end
  end

  property :named_past_tense_encoding do
    for_all entries in such_that(f in float() when f > 0.0) do
      summed = Sum.ed(abs(entries), entries, "myfunc")
      actual = Poison.encode!(summed) |> Poison.decode!(keys: :atoms)
      actual.data == Sum.encoder_data(summed)
    end
  end
end
