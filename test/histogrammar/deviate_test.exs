defmodule Histogrammar.DeviateTest do
  use ExUnit.Case, async: false
  use Quixir
  alias Histogrammar.Deviate
  alias Histogrammar.Average
  alias Histogrammar.Util

  doctest Histogrammar.Deviate
  @threshold 1.0e-9

  def uniform_present_tense(xs) do
    Enum.into(xs, Deviate.ing(&Util.identity/1))
  end

  def randomly_weighted_present_tense(weights) do
    Enum.reduce(weights, Deviate.ing(&Util.identity/1), fn
      (weight, deviating) ->
        Histogrammar.fill(deviating, weight, weight)
    end)
  end

  def check_combine(first, second, expected) do
    case {first.mean, second.mean} do
      {nil, nil} -> expected.entries == 0.0 and is_nil(expected.mean)
      {nil, _} ->
        Histogrammar.encoder_data(expected) == Histogrammar.encoder_data(second)
      {_, nil} ->
        Histogrammar.encoder_data(expected) == Histogrammar.encoder_data(first)
      _ ->
        entries = first.entries + second.entries
        expected.entries == entries and
        (expected.mean - (first.mean * first.entries +
         second.mean * second.entries) / entries) < @threshold
    end
  end

  test :fill_one do
    ptest x: float() do
      initial = Deviate.ing(&Util.identity/1)
      case Histogrammar.fill(initial, x, 1.0) do
        deviating ->
          assert abs(deviating.mean - x) < @threshold and deviating.variance == 0.0
      end
    end
  end

  test :fill_constantly_weighted do
    ptest xs: list(min: 1, max: 100, of: float()) do
      deviating = uniform_present_tense(xs)
      mean = Enum.reduce(xs, 0.0, fn
        (weight, sum) ->
          sum + weight
      end) / (1.0 * length(xs))
      assert deviating.entries == length(xs) and
        abs(deviating.mean - mean) < @threshold
    end
  end

  test :fill_randomly_weighted do
    ptest weights: list(min: 1, max: 100, of: float()) do
      deviating = weights
                  |> randomly_weighted_present_tense
      if length(weights |> Enum.filter(&(&1 > 0))) == 0 do
        assert is_nil(deviating.mean)
      else
        sum = Enum.reduce(weights, 0.0, fn
          (weight, sum) ->
            if weight > 0.0, do: sum + :math.pow(weight, 2), else: sum
        end)
        mean = sum / deviating.entries
        assert abs(deviating.mean - mean) < @threshold
      end
    end
  end

  test :past_tense_combine do
    ptest a: float(min: 1.0), b: float(min: 1.0) do
      x = Deviate.ed(a, a, :math.sqrt(a))
      y = Deviate.ed(b, b, :math.sqrt(b))
      z = Histogrammar.combine(x, y)
      mean = (a * a + b * b) / a + b
      assert z.mean - mean < @threshold
      check_combine(x, y, z)
    end
  end

  test :uniform_present_tense_combine do
    ptest a: list(max: 100, of: float()), b: list(max: 100, of: float()) do
      x = uniform_present_tense(a)
      y = uniform_present_tense(b)
      z = Histogrammar.combine(x, y)
      if is_nil(z.mean) do
        assert length(a) + length(b) == 0
      else
        mean = Enum.reduce(a ++ b, 0.0, fn (weight, sum) ->
          weight + sum
        end) / length(a ++ b)
        assert z.mean - mean < @threshold
      end
      assert check_combine(x, y, z)
    end
  end

  test :mixed_present_tense_combine do
    ptest a: list(max: 100, of: float()), b: list(max: 100, of: float()) do
      x = uniform_present_tense(a)
      y = randomly_weighted_present_tense(b)
      z = Histogrammar.combine(x, y)

      assert check_combine(x, y, z)
    end
  end

  test :random_present_tense_combine do
    ptest a: list(max: 100, of: float()), b: list(max: 100, of: float()) do
      x = randomly_weighted_present_tense(a)
      y = randomly_weighted_present_tense(b)
      z = Histogrammar.combine(x, y)

      assert check_combine(x, y, z)
    end
  end

  test :mixed_tense_combine do
    ptest weights: list(of: float()), b: float() do
      x = uniform_present_tense(weights)
      y = Deviate.ed(abs(b), if(b == 0.0, do: nil, else: b), if(b == 0.0, do: nil, else: :math.sqrt(abs(b))))
      z = Histogrammar.combine(x, y)
      assert check_combine(x, y, z)
    end
  end

  test :transforming_fill do
    ptest weights: list(min: 1, max: 100, of: float()) do
      transform = fn (x) -> x * x end
      deviating = Enum.into(weights, Deviate.ing(transform))
      averaging = Enum.into(weights, Average.ing(transform))
      assert deviating.mean == averaging.mean
    end
  end

  test :present_tense_encoding do
    ptest weights: list(max: 100, of: float()) do
      expected = uniform_present_tense(weights)
      actual = Poison.encode!(expected) |> Poison.decode!(keys: :atoms)
      assert actual.data == Histogrammar.encoder_data(expected)
    end
  end

  test :named_present_tense_encoding do
    ptest weights: list(max: 100, of: float()) do
      expected = Enum.into(weights, Deviate.ing(&Util.identity/1, "myfunc"))
      actual = Poison.encode!(expected) |> Poison.decode!(keys: :atoms)
      assert actual.data == Histogrammar.encoder_data(expected)
    end
  end

  test :past_tense_encoding do
    ptest entries: float(min: 1.0) do
      expected = Deviate.ed(abs(entries), entries, :math.sqrt(entries))
      actual = Poison.encode!(expected) |> Poison.decode!(keys: :atoms)
      assert actual.data == Histogrammar.encoder_data(expected)
    end
  end

  test :named_past_tense_encoding do
    ptest entries: float(min: 1.0) do
      deviated = Deviate.ed(abs(entries), entries, :math.sqrt(entries), "myfunc")
      actual = Poison.encode!(deviated) |> Poison.decode!(keys: :atoms)
      assert actual.data == Histogrammar.encoder_data(deviated)
    end
  end

  test "Anscombe's Quartet" do
    x1 = [10.0, 8.0, 13.0, 9.0, 11.0, 14.0, 6.0, 4.0, 12.0, 7.0, 5.0]
          |> Enum.into(Deviate.ing(&Util.identity/1))
    assert abs(x1.mean - 9.0) < @threshold
    assert abs(x1.variance - 10.0) < @threshold
    x2 = [8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 19.0, 8.0, 8.0, 8.0]
          |> Enum.into(Deviate.ing(&Util.identity/1))
    assert abs(x2.mean - 9.0) < @threshold
    assert abs(x1.variance - 10.0) < @threshold
    y1 = [8.04, 6.95, 7.58, 8.81, 8.33, 9.96, 7.24, 4.26, 10.84, 4.82, 5.68]
          |> Enum.into(Deviate.ing(&Util.identity/1))
    assert abs(y1.mean - 7.50) < 0.001
    assert abs(y1.variance - 3.75) < 0.003
    y2 = [9.14, 8.14, 8.74, 8.77, 9.26, 8.10, 6.13, 3.10, 9.13, 7.26, 4.74]
          |> Enum.into(Deviate.ing(&Util.identity/1))
    assert abs(y2.mean - 7.50) < 0.001
    assert abs(y1.variance - 3.75) < 0.003
  end
end
