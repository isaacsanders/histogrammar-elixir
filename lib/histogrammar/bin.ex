defmodule Histogrammar.Binning do
  defstruct num: 1,
            low: nil,
            high: nil,
            quantity: nil,
            underflow: Histogrammar.Count.ing(),
            overflow: Histogrammar.Count.ing(),
            nanflow: Histogrammar.Count.ing(),
            entries: 0.0,
            values: []

  defimpl Histogrammar.PresentTense, for: __MODULE__ do
    alias Histogrammar.Binning

    def fill(%{ __struct__: @for } = binning, datum, weight) when weight > 0.0 do
      q = binning.quantity.(datum)
      cond do
        is_nil(q) ->
          do_fill_nanflow(binning, datum, weight)
        q < binning.low ->
          do_fill_underflow(binning, datum, weight)
        q > binning.high ->
          do_fill_overflow(binning, datum, weight)
        true ->
          bin = trunc(binning.num *
           (q - binning.low) / (binning.high - binning.low))
          do_fill_bin(binning, datum, weight, bin)
      end
    end
    def fill(binning, _datum, _weight), do: binning

    defp do_fill_nanflow(%Binning{ nanflow: nanflow } = binning, datum, weight),
      do: %{ binning | entries: binning.entries + weight,
                       nanflow: Histogrammar.fill(nanflow, datum, weight) }

    defp do_fill_underflow(%Binning{ underflow: underflow } = binning, datum, weight),
      do: %{ binning | entries: binning.entries + weight,
                       underflow: Histogrammar.fill(underflow, datum, weight) }

    defp do_fill_overflow(%Binning{ overflow: overflow } = binning, datum, weight),
      do: %{ binning | entries: binning.entries + weight,
                       overflow: Histogrammar.fill(overflow, datum, weight) }

    defp do_fill_bin(%Binning{ values: values } = binning, bin, datum, weight),
      do: %{ binning | entries: binning.entries + weight,
                       values: List.update_at(values, bin, &(Histogrammar.fill(&1, datum, weight))) }

    def to_past_tense(%{ __struct__: @for, low: low, high: high,
      entries: entries, values: values, underflow: underflow,
      overflow: overflow, nanflow: nanflow } = binning),
      do: Histogrammar.Bin.ed(low, high, entries,
       Enum.map(values, &Histogrammar.to_past_tense/1),
       Histogrammar.to_past_tense(underflow),
       Histogrammar.to_past_tense(overflow),
       Histogrammar.to_past_tense(nanflow))
  end
end

defmodule Histogrammar.Binned do
  defstruct low: nil,
            high: nil,
            entries: 0.0,
            values: [],
            underflow: Histogrammar.Count.ed(0.0),
            overflow: Histogrammar.Count.ed(0.0),
            nanflow: Histogrammar.Count.ed(0.0)
end

defmodule Histogrammar.Bin do
  use Histogrammar.Primitive,
    histogrammar_type: "Bin",
    present_tense: Histogrammar.Binning,
    past_tense: Histogrammar.Binned

  def ing(num, low, high, opts \\ []) do
    quantity = Keyword.get(opts, :quantity, &Histogrammar.Util.identity/1)
    value = Keyword.get(opts, :value, Histogrammar.Count.ing())
    underflow = Keyword.get(opts, :underflow, Histogrammar.Count.ing())
    overflow = Keyword.get(opts, :overflow, Histogrammar.Count.ing())
    nanflow = Keyword.get(opts, :nanflow, Histogrammar.Count.ing())

    ing(num, low, high, quantity, value, underflow, overflow, nanflow)
  end

  def ing(num, low, high, quantity, value, underflow, overflow, nanflow)
    when is_integer(num) and num >= 1 and
         is_float(low) and is_float(high) and low < high and
         is_function(quantity, 1),
    do: %Histogrammar.Binning{num: num, low: low, high: high, quantity: quantity,
                              underflow: underflow, overflow: overflow,
                              nanflow: nanflow, values: List.duplicate(value, num)}

  def ed(low, high, entries, values, underflow, overflow, nanflow),
    do: %Histogrammar.Binned{low: low, high: high, entries: entries,
                             values: values, underflow: underflow,
                             overflow: overflow, nanflow: nanflow }
end
