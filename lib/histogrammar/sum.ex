defmodule Histogrammar.Summing do
  defstruct quantity: nil,
            name: nil,
            entries: 0.0,
            sum: 0.0

  defimpl Histogrammar.PresentTense, for: __MODULE__ do
    alias Histogrammar.Summing

    def fill(%Summing{} = summing, datum, weight) when weight > 0.0 do
      q = summing.quantity.(datum)
      do_fill(summing, weight, q)
    end
    def fill(%Summing{} = summing, _datum, _weight), do: summing

    defp do_fill(%Summing{entries: entries, sum: sum} = summing, weight, q),
      do: %{ summing | entries: entries + weight, sum: sum + q }

    def to_past_tense(%Summing{ entries: entries, sum: sum, name: name }) do
      Histogrammar.Sum.ed(entries, sum, name)
    end
  end
end

defmodule Histogrammar.Summed do
  defstruct entries: 0.0,
            sum: 0.0,
            name: nil

  defimpl Histogrammar.PastTense, for: __MODULE__ do
    alias Histogrammar.Summed
    def combine(%Summed{} = first,
                %Summed{} = second) do
      name = if first.name == second.name, do: first.name, else: nil
      Histogrammar.Sum.ed(first.entries + second.entries, first.sum + second.sum, name)
    end

    def encoder_data(%Summed{ entries: entries, sum: sum, name: nil}),
      do: %{ entries: entries, sum: sum }
    def encoder_data(%Summed{ entries: entries, sum: sum, name: name }),
      do: %{ entries: entries, sum: sum, name: name }
  end
end

defmodule Histogrammar.Sum do
  alias Histogrammar.Summing
  alias Histogrammar.Summed

  use Histogrammar.Primitive,
    histogrammar_type: "Sum",
    present_tense: Histogrammar.Summing,
    past_tense: Histogrammar.Summed

  def ing(quantity, name \\ nil) when is_function(quantity, 1) do
    %Summing{quantity: quantity, name: name}
  end

  def ed(entries, sum, name \\ nil) when is_number(entries) and is_number(sum) do
    %Summed{entries: entries, sum: sum, name: name}
  end
end
