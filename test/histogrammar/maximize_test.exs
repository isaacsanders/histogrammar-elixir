defmodule Histogrammar.MaximizeTest do
  use ExUnit.Case, async: false
  use Quixir
  alias Histogrammar.Maximize
  alias Histogrammar.Util

  doctest Histogrammar.Maximize

  def uniform_present_tense(xs) do
    Enum.into(xs, Maximize.ing(&Util.identity/1))
  end

  def randomly_weighted_present_tense(weights) do
    Enum.reduce(weights, Maximize.ing(&Util.identity/1), fn
      (weight, averaging) ->
        Histogrammar.fill(averaging, weight, weight)
    end)
  end

  test :fill_one do
    ptest x: float() do
      initial = Maximize.ing(&Util.identity/1)
      maximizing = Histogrammar.fill(initial, x, 1.0)
      assert x == maximizing.max
    end
  end

  test :fill_constantly_weighted do
    ptest xs: list(min: 1, of: float()) do
      maximizing = uniform_present_tense(xs)
      max = Enum.max(xs, fn -> nil end)
      assert maximizing.entries == length(xs) and
      maximizing.max == max
    end
  end

  test :fill_randomly_weighted do
    ptest weights: list(min: 1, of: float()) do
      maximizing = weights
                    |> Enum.filter(&(&1 > 0))
                    |> randomly_weighted_present_tense
      max = weights
            |> Enum.filter(&(&1 > 0))
            |> Enum.max(fn -> nil end)
      assert maximizing.max == max
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
      expected = Enum.into(weights, Maximize.ing(&Util.identity/1, "myfunc"))
      actual = Poison.encode!(expected) |> Poison.decode!(keys: :atoms)
      assert actual.data == Histogrammar.encoder_data(expected)
    end
  end

  test :past_tense_encoding do
    ptest entries: float(min: 1.0) do
      expected = Maximize.ed(abs(entries), entries)
      actual = Poison.encode!(expected) |> Poison.decode!(keys: :atoms)
      assert actual.data == Histogrammar.encoder_data(expected)
    end
  end

  test :named_past_tense_encoding do
    ptest entries: float(min: 1.0) do
      expected = Maximize.ed(abs(entries), entries, "myfunc")
      actual = Poison.encode!(expected) |> Poison.decode!(keys: :atoms)
      assert actual.data == Histogrammar.encoder_data(expected)
    end
  end
end
