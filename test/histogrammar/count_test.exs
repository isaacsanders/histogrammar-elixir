defmodule Histogrammar.CountTest do
  use ExUnit.Case, async: false
  use ExCheck
  alias Histogrammar.Count

  doctest Histogrammar.Count

  def uniform_present_tense(xs) do
    Enum.reduce(xs, Count.ing(), fn
      (x, counting) ->
        Count.fill(counting, x, 1.0)
    end)
  end

  def random_present_tense(weights) do
    Enum.reduce(weights, Count.ing(), fn
      (weight, counting) ->
        Count.fill(counting, weight, weight)
    end)
  end

  property :fill_constantly_weighted do
    for_all xs in list(int()) do
      counting = uniform_present_tense(xs)
      counting.entries == length(xs)
    end
  end

  property :fill_randomly_weighted do
    for_all weights in list(int()) do
      counting = random_present_tense(weights)
      Enum.reduce(weights, 0.0, fn
        (weight, sum) ->
          if weight > 0.0, do: sum + weight, else: sum
      end) == counting.entries
    end
  end

  property :past_tense_combine do
    for_all {a, b} in {int(), int()} do
      x = Count.ed(a)
      y = Count.ed(b)
      z = Count.combine(x, y)
      z.entries == a + b
    end
  end

  property :uniform_present_tense_combine do
    for_all {a, b} in {list(int()), list(int())} do
      x = uniform_present_tense(a)
      y = uniform_present_tense(b)
      z = Count.combine(x, y)
      z.entries == (length(a) + length(b))
    end
  end

  property :mixed_present_tense_combine do
    for_all {a, b} in {list(int()), list(int())} do
      x = uniform_present_tense(a)
      y = random_present_tense(b)
      z = Count.combine(x, y)
      z.entries == (length(a) +
       Enum.reduce(b, 0.0, &(if &1 > 0.0, do: &1 + &2, else: &2)))
    end
  end

  property :random_present_tense_combine do
    for_all {a, b} in {list(int()), list(int())} do
      x = random_present_tense(a)
      y = random_present_tense(b)
      z = Count.combine(x, y)
      first = Enum.reduce(a, 0.0, &(if &1 > 0.0, do: &1 + &2, else: &2))
      second = Enum.reduce(b, 0.0, &(if &1 > 0.0, do: &1 + &2, else: &2))
      z.entries == (first + second)
    end
  end

  property :mixed_tense_combine do
    for_all {weights, b} in {list(int()), int()} do
      x = uniform_present_tense(weights)
      y = Count.ed(b)
      z = Count.combine(x, y)
      z.entries == b + x.entries
    end
  end

  property :transforming_fill do
    for_all weights in list(int()) do
      transform = fn (x) -> x * x end
      counting = Enum.reduce(weights, Count.ing(transform), fn (weight, counting) ->
        Count.fill(counting, weight, weight)
      end)
      sum_of_squares = Enum.reduce(weights, 0.0, &(if &1 > 0.0, do: transform.(&1) + &2, else: &2))
      counting.entries == sum_of_squares
    end
  end

  property :present_tense_encoding do
    for_all weights in list(int()) do
      counting = Enum.into(weights, Count.ing())
      Poison.encode!(counting) == ~s({"version":"1.0","type":"Count","data":#{length(weights) * 1.0}})
    end
  end

  property :past_tense_encoding do
    for_all entries in int() do
      counted = Count.ed(abs(entries))
      Poison.encode!(counted) == ~s({"version":"1.0","type":"Count","data":#{abs(entries)}})
    end
  end
end
