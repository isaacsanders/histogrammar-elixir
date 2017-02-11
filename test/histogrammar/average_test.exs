defmodule Histogrammar.AverageTest do
  use ExUnit.Case, async: false
  use ExCheck
  alias Histogrammar.Average
  alias Histogrammar.Util

  doctest Histogrammar.Average
  @threshold 1.0e-10

  def uniform_present_tense(xs) do
    Enum.into(xs, Average.ing(&Util.identity/1))
  end

  def randomly_weighted_present_tense(weights) do
    Enum.reduce(weights, Average.ing(&Util.identity/1), fn
      (weight, averaging) ->
        Average.fill(averaging, weight, weight)
    end)
  end

  def check_combine(first, second, expected) do
    case {first.mean, second.mean} do
      {nil, nil} -> expected.entries == 0.0 and is_nil(expected.mean)
      {nil, _} -> expected == second
      {_, nil} -> expected == first
      _ ->
        entries = first.entries + second.entries
        expected.entries == entries and
        expected.mean == (first.mean * first.entries +
         second.mean * second.entries) / entries
    end
  end

  property :fill_one do
    for_all x in float do
      averaging = Average.ing(&Util.identity/1) |> Average.fill(x, 1.0)
      averaging.mean == x
    end
  end

  property :fill_constantly_weighted do
    for_all xs in such_that(xxs in list(int()) when length(xxs) > 0) do
      averaging = uniform_present_tense(xs)
      mean = Enum.reduce(xs, 0.0, fn
        (weight, sum) ->
          sum + weight
      end) / (1.0 * length(xs))
      averaging.entries == length(xs) and
      abs(averaging.mean - mean) < @threshold
    end
  end

  property :fill_randomly_weighted do
    for_all weights in such_that(wweights in list(int()) when length(wweights) > 0) do
      averaging = weights
                  |> Enum.filter(&(&1 > 0))
                  |> randomly_weighted_present_tense
      if length(weights |> Enum.filter(&(&1 > 0))) == 0 do
        is_nil(averaging.mean)
      else
        sum = Enum.reduce(weights, 0.0, fn
          (weight, sum) ->
            if weight > 0.0, do: sum + :math.pow(weight, 2), else: sum
        end)
        mean = sum / averaging.entries
        abs(averaging.mean - mean) < @threshold
      end
    end
  end

  property :past_tense_combine do
    for_all {a, b} in such_that({q, p} in {float(), float()} when q > 0 and p > 0) do
      x = Average.ed(a, a)
      y = Average.ed(b, b)
      z = Average.combine(x, y)
      mean = (a * a + b * b) / a + b
      z.mean - mean < @threshold
    end
  end

  property :uniform_present_tense_combine do
    for_all {a, b} in {list(int()), list(int())} do
      x = uniform_present_tense(a)
      y = uniform_present_tense(b)
      z = Average.combine(x, y)
      if is_nil(z.mean) do
        length(a) + length(b) == 0
      else
        mean = Enum.reduce(a ++ b, 0.0, fn (weight, sum) ->
          weight + sum
        end) / length(a ++ b)
        z.mean - mean < @threshold
      end
    end
  end

  property :mixed_present_tense_combine do
    for_all {a, b} in {list(int()), list(int())} do
      x = uniform_present_tense(a)
      y = randomly_weighted_present_tense(b)
      z = Average.combine(x, y)

      case {x.mean, y.mean} do
        {nil, nil} -> z.entries == 0.0 and is_nil(z.mean)
        {nil, _} -> z == y
        {_, nil} -> z == x
        _ ->
          entries = x.entries + y.entries
          z.entries == entries and
          z.mean == (x.mean * x.entries + y.mean * y.entries) / entries
      end
    end
  end

  property :random_present_tense_combine do
    for_all {a, b} in {list(int()), list(int())} do
      x = randomly_weighted_present_tense(a)
      y = randomly_weighted_present_tense(b)
      z = Average.combine(x, y)

      check_combine(x, y, z)
    end
  end

  property :mixed_tense_combine do
    for_all {weights, b} in {list(int()), float()} do
      x = uniform_present_tense(weights)
      y = Average.ed(b, b)
      z = Average.combine(x, y)
      check_combine(x, y, z)
    end
  end

  property :transforming_fill do
    for_all weights in such_that(l in list(int()) when length(l) > 0) do
      transform = fn (x) -> x * x end
      averaging = Enum.reduce(weights, Average.ing(transform), fn (weight, averaging) ->
        Average.fill(averaging, weight, 1.0)
      end)
      sum_of_squares = Enum.reduce(weights, 0.0, &(transform.(&1) + &2)) / averaging.entries
      averaging.mean - sum_of_squares < @threshold
    end
  end

  property :present_tense_encoding do
    for_all weights in list(int()) do
      averaging = Enum.reduce(weights, Average.ing(&Util.identity/1), fn (weight, averaging) ->
        Average.fill(averaging, weight, 1.0)
      end)
      mean = if length(weights) > 0, do: Enum.reduce(weights, 0.0, &(&1 + &2)) / length(weights), else: nil
      actual = Poison.encode!(averaging) |> Poison.decode!(keys: :atoms)
      if is_nil(mean) do
        is_nil(actual.data.mean)
      else
        actual.data.mean - mean < @threshold
      end
    end
  end

  property :named_present_tense_encoding do
    for_all weights in list(int()) do
      averaging = Enum.reduce(weights, Average.ing(&Util.identity/1, "myfunc"), fn (weight, averaging) ->
        Average.fill(averaging, weight, 1.0)
      end)
      mean = if length(weights) > 0, do: Enum.reduce(weights, 0.0, &(&1 + &2)) / length(weights), else: nil
      actual = Poison.encode!(averaging) |> Poison.decode!(keys: :atoms)
      if is_nil(mean) do
        is_nil(actual.data.mean) and actual.data.name == "myfunc"
      else
        actual.data.mean - mean < @threshold and actual.data.name == "myfunc"
      end
    end
  end

  property :past_tense_encoding do
    for_all entries in float() do
      averaged = Average.ed(abs(entries), entries)
      actual = Poison.encode!(averaged) |> Poison.decode!(keys: :atoms)
      actual.data.mean == entries
    end
  end

  property :named_past_tense_encoding do
    for_all entries in float() do
      averaged = Average.ed(abs(entries), entries, "myfunc")
      actual = Poison.encode!(averaged) |> Poison.decode!(keys: :atoms)
      actual.data.mean == entries and actual.data.name == "myfunc"
    end
  end

  test "Anscombe's Quartet" do
    x1 = [10.0, 8.0, 13.0, 9.0, 11.0, 14.0, 6.0, 4.0, 12.0, 7.0, 5.0]
          |> Enum.into(Average.ing(&Util.identity/1))
    assert abs(x1.mean - 9.0) < @threshold
    x2 = [8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 19.0, 8.0, 8.0, 8.0]
          |> Enum.into(Average.ing(&Util.identity/1))
    assert abs(x2.mean - 9.0) < @threshold
    y1 = [8.04, 6.95, 7.58, 8.81, 8.33, 9.96, 7.24, 4.26, 10.84, 4.82, 5.68]
          |> Enum.into(Average.ing(&Util.identity/1))
    assert abs(y1.mean - 7.50) < 0.001
    y2 = [9.14, 8.14, 8.74, 8.77, 9.26, 8.10, 6.13, 3.10, 9.13, 7.26, 4.74]
          |> Enum.into(Average.ing(&Util.identity/1))
    assert abs(y2.mean - 7.50) < 0.001
  end
end
