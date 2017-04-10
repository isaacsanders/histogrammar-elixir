defmodule Histogrammar.Counting do
  defstruct transform: &Histogrammar.Util.identity/1,
            entries: 0.0

  defimpl Histogrammar.PresentTense, for: __MODULE__ do
    alias Histogrammar.Counting

    def fill(%Counting{} = counting, _datum, weight) when weight > 0.0 do
      %{ counting | entries: counting.entries + counting.transform.(weight) }
    end
    def fill(counting, _datum, _weight), do: counting

    def to_past_tense(%Counting{ entries: entries }) do
      Histogrammar.Count.ed(entries)
    end
  end
end

defmodule Histogrammar.Counted do
  defstruct entries: 0.0

  defimpl Histogrammar.PastTense, for: __MODULE__ do
    def combine(%Histogrammar.Counted{} = first,
                %Histogrammar.Counted{} = second) do
      Histogrammar.Count.ed(first.entries + second.entries)
    end

    def encoder_data(%Histogrammar.Counted{ entries: entries }), do: entries
  end
end

defmodule Histogrammar.Count do
  use Histogrammar.Primitive,
    histogrammar_type: "Count",
    present_tense: Histogrammar.Counting,
    past_tense: Histogrammar.Counted

  def ing(),
    do: ing(&Histogrammar.Util.identity/1)
  def ing(transform)
    when is_function(transform, 1),
    do: %Histogrammar.Counting{transform: transform, entries: 0.0}

  def ed(entries) do
    %Histogrammar.Counted{entries: entries}
  end
end
