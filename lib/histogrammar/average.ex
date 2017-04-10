defmodule Histogrammar.Averaging do
  defstruct quantity: nil,
            name: nil,
            entries: 0.0,
            mean: nil

  defimpl Histogrammar.PresentTense, for: __MODULE__ do
    alias Histogrammar.Averaging

    def fill(%Averaging{} = averaging, datum, weight) when weight > 0.0 do
        q = averaging.quantity.(datum)
        mean = if averaging.entries == 0.0, do: 0.0, else: averaging.mean
        entries = averaging.entries + weight
        mean = q && mean

        delta = q - mean
        shift = delta * weight / entries

        %{ averaging | entries: entries, mean: mean + shift }
    end
    def fill(%Averaging{} = averaging, _datum, _weight), do: averaging

    def to_past_tense(%Averaging{ entries: entries, mean: mean, name: name }) do
      Histogrammar.Average.ed(entries, mean, name)
    end
  end
end

defmodule Histogrammar.Averaged do
  alias Histogrammar.Averaged
  defstruct entries: 0.0,
            mean: nil,
            name: nil

  defimpl Histogrammar.PastTense, for: __MODULE__ do
    alias Histogrammar.Averaged
    def combine(%Averaged{} = a, %Averaged{} = b) do
      name = if a.name == b.name, do: a.name, else: nil
      case {a.entries, b.entries} do
        {0.0, 0.0} -> %Averaged{entries: 0.0, mean: nil, name: name}
        {_, 0.0} -> a
        {0.0, _} -> b
        _ ->
          entries = a.entries + b.entries
          Histogrammar.Average.ed(entries, (a.entries * a.mean + b.entries * b.mean) / entries)
      end
    end

    def encoder_data(%Averaged{ entries: entries, mean: mean, name: nil}),
      do: %{ entries: entries, mean: mean }
    def encoder_data(%Averaged{ entries: entries, mean: mean, name: name }),
      do: %{ entries: entries, mean: mean, name: name }
  end
end

defmodule Histogrammar.Average do
  use Histogrammar.Primitive,
    histogrammar_type: "Average",
    present_tense: Histogrammar.Averaging,
    past_tense: Histogrammar.Averaged

  def ing(quantity, name \\ nil) when is_function(quantity, 1) do
    %Histogrammar.Averaging{quantity: quantity, name: name}
  end

  def ed(entries, mean, name \\ nil)
  def ed(entries, mean, name) when is_number(entries) and is_number(mean) do
    %Histogrammar.Averaged{entries: entries, mean: mean, name: name}
  end

  def ed(0.0, nil, name), do: %Histogrammar.Averaged{entries: 0.0, mean: nil, name: name}
end
