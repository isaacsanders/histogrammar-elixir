defmodule Histogrammar.MinimizeTest do
  use ExUnit.Case, async: false
  use Quixir
  alias Histogrammar.Minimize
  alias Histogrammar.Util

  doctest Histogrammar.Minimize

  def uniform_present_tense(xs) do
    Enum.into(xs, Minimize.ing(&Util.identity/1))
  end

  def randomly_weighted_present_tense(weights) do
    Enum.reduce(weights, Minimize.ing(&Util.identity/1), fn
      (weight, averaging) ->
        Histogrammar.fill(averaging, weight, weight)
    end)
  end

  test :fill_one do
    ptest x: float() do
      initial = Minimize.ing(&Util.identity/1)
      minimizing = Histogrammar.fill(initial, x, 1.0)
      assert x == minimizing.min
    end
  end

  test :fill_constantly_weighted do
    ptest xs: list(min: 1, of: float()) do
      minimizing = uniform_present_tense(xs)
      min = Enum.min(xs, fn -> nil end)
      assert minimizing.entries == length(xs) and
      minimizing.min == min
    end
  end

  test :fill_randomly_weighted do
    ptest weights: list(min: 1, of: float()) do
      minimizing = weights
                    |> Enum.filter(&(&1 > 0))
                    |> randomly_weighted_present_tense
      min = weights
            |> Enum.filter(&(&1 > 0))
            |> Enum.min(fn -> nil end)
      assert minimizing.min == min
    end
  end

  test :present_tense_encoding do
    ptest weights: list(of: float()) do
      expected = uniform_present_tense(weights)
      actual = Poison.encode!(expected) |> Poison.decode!(keys: :atoms)
      assert actual.data == Histogrammar.encoder_data(expected)
    end
  end

  test :named_present_tense_encoding do
    ptest weights: list(of: float()) do
      expected = Enum.into(weights, Minimize.ing(&Util.identity/1, "myfunc"))
      actual = Poison.encode!(expected) |> Poison.decode!(keys: :atoms)
      assert actual.data == Histogrammar.encoder_data(expected)
    end
  end

  test :past_tense_encoding do
    ptest entries: float(min: 1.0) do
      expected = Minimize.ed(abs(entries), entries)
      actual = Poison.encode!(expected) |> Poison.decode!(keys: :atoms)
      assert actual.data == Histogrammar.encoder_data(expected)
    end
  end

  test :named_past_tense_encoding do
    ptest entries: float(min: 1.0) do
      expected = Minimize.ed(abs(entries), entries, "myfunc")
      actual = Poison.encode!(expected) |> Poison.decode!(keys: :atoms)
      assert actual.data == Histogrammar.encoder_data(expected)
    end
  end
end
