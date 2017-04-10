defmodule Histogrammar.AverageTest do
  use ExUnit.Case
  use Quixir
  alias Histogrammar.Average
  alias Histogrammar.Util
  require Logger

  doctest Histogrammar.Average
  @threshold 1.0e-9

  def uniform_present_tense(xs) do
    Enum.into(xs, Average.ing(&Util.identity/1))
  end

  def randomly_weighted_present_tense(weights) do
    Enum.reduce(weights, Average.ing(&Util.identity/1), fn
      (weight, averaging) ->
        Histogrammar.fill(averaging, weight, weight)
    end)
  end

  def check_combine(first, second, expected) do
    case {first.mean, second.mean} do
      {nil, nil} ->
        expected.entries == 0.0 and is_nil(expected.mean)
      {nil, _} ->
        Histogrammar.encoder_data(expected) == Histogrammar.encoder_data(second)
      {_, nil} ->
        Histogrammar.encoder_data(expected) == Histogrammar.encoder_data(first)
      _ ->
        entries = first.entries + second.entries
        expected.entries == entries and
        expected.mean == (first.mean * first.entries +
         second.mean * second.entries) / entries
    end
  end

  test "filling one means an average of one" do
    ptest x: float() do
      averaging = Average.ing(&Util.identity/1) |> Histogrammar.fill(x, 1.0)
      assert averaging.mean == x
    end
  end

  test "filling with constant weighting means a simple average" do
    ptest xs: list(min: 1, of: float()) do
      averaging = uniform_present_tense(xs)
      mean = Enum.reduce(xs, 0.0, fn
        (weight, sum) ->
          sum + weight
      end) / (1.0 * length(xs))
      assert averaging.entries == length(xs) and
      abs(averaging.mean - mean) < @threshold
    end
  end

  test "filling with an elements weight requires a slightly more complicated average" do
    ptest weights: list(min: 1, of: float()) do
      averaging = weights
                  |> Enum.filter(&(&1 > 0))
                  |> randomly_weighted_present_tense
      if length(weights |> Enum.filter(&(&1 > 0))) == 0 do
        assert is_nil(averaging.mean)
      else
        sum = Enum.reduce(weights, 0.0, fn
          (weight, sum) ->
            if weight > 0.0, do: sum + :math.pow(weight, 2), else: sum
        end)
        mean = sum / averaging.entries
        assert abs(averaging.mean - mean) < @threshold
      end
    end
  end

  test "combine two structures from the past tense" do
    ptest a: float(min: 1.0), b: float(min: 1.0) do
      x = Average.ed(a, a)
      y = Average.ed(b, b)
      z = Histogrammar.combine(x, y)
      mean = (a * a + b * b) / a + b
      assert z.mean - mean < @threshold
      assert check_combine(x, y, z)
    end
  end

  test "combine present tense structures" do
    ptest as: list(min: 1, of: float()), bs: list(min: 1, of: float()) do
      x = uniform_present_tense(as)
      y = uniform_present_tense(bs)
      z = Histogrammar.combine(x, y)
      mean = Enum.reduce(as ++ bs, 0.0, fn (weight, sum) ->
        weight + sum
      end) / length(as ++ bs)
      assert assert z.mean - mean < @threshold
      assert check_combine(x, y, z)
    end
  end

  test :mixed_present_tense_combine do
    ptest a: list(of: float()), b: list(of: float()) do
      x = uniform_present_tense(a)
      y = randomly_weighted_present_tense(b)
      z = Histogrammar.combine(x, y)

      assert check_combine(x, y, z)
    end
  end

  test :random_present_tense_combine do
    ptest a: list(of: float()), b: list(of: float()) do
      x = randomly_weighted_present_tense(a)
      y = randomly_weighted_present_tense(b)
      z = Histogrammar.combine(x, y)

      assert check_combine(x, y, z)
    end
  end

  test :mixed_tense_combine do
    ptest weights: list(of: float()), b: float(min: 1.0) do
      x = uniform_present_tense(weights)
      y = Average.ed(b, b)
      z = Histogrammar.combine(x, y)
      assert check_combine(x, y, z)
    end
  end

  test :transforming_fill do
    ptest weights: list(min: 1, of: int()) do
      transform = fn (x) -> x * x end
      averaging = Enum.reduce(weights, Average.ing(transform), fn (weight, averaging) ->
        Histogrammar.fill(averaging, weight, 1.0)
      end)
      sum_of_squares = Enum.reduce(weights, 0.0, &(transform.(&1) + &2)) / averaging.entries
      assert averaging.mean - sum_of_squares < @threshold
    end
  end

  test :present_tense_encoding do
    ptest weights: list(of: int()) do
      averaging = Enum.reduce(weights, Average.ing(&Util.identity/1), fn (weight, averaging) ->
        Histogrammar.fill(averaging, weight, 1.0)
      end)
      mean = if length(weights) > 0, do: Enum.reduce(weights, 0.0, &(&1 + &2)) / length(weights), else: nil
      actual = Poison.encode!(averaging) |> Poison.decode!(keys: :atoms)
      if is_nil(mean) do
        assert is_nil(actual.data.mean)
      else
        assert actual.data.mean - mean < @threshold
      end
    end
  end

  test :named_present_tense_encoding do
    ptest weights: list(of: int()) do
      averaging = Enum.into(weights, Average.ing(&Util.identity/1, "myfunc"))
      mean = if length(weights) > 0, do: Enum.reduce(weights, 0.0, &(&1 + &2)) / length(weights), else: nil
      actual = Poison.encode!(averaging) |> Poison.decode!(keys: :atoms)
      if is_nil(mean) do
        assert is_nil(actual.data.mean) and actual.data.name == "myfunc"
      else
        assert actual.data.mean - mean < @threshold and actual.data.name == "myfunc"
      end
    end
  end

  test :past_tense_encoding do
    ptest entries: float() do
      averaged = Average.ed(abs(entries), entries)
      actual = Poison.encode!(averaged) |> Poison.decode!(keys: :atoms)
      assert actual.data.mean == entries
    end
  end

  test :named_past_tense_encoding do
    ptest entries: float() do
      averaged = Average.ed(abs(entries), entries, "myfunc")
      actual = Poison.encode!(averaged) |> Poison.decode!(keys: :atoms)
      assert actual.data.mean == entries and actual.data.name == "myfunc"
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
