defmodule Histogrammar.Counting do
  defstruct transform: &Histogrammar.Util.identity/1,
            entries: 0.0
end

defimpl Poison.Encoder, for: Histogrammar.Counting do
  def encode(%Histogrammar.Counting{} = counting, options) do
    Poison.Encoder.Map.encode(%{
      version: Histogrammar.specification_version,
      type: "Count",
      data: counting.entries
    }, options)
  end
end

defmodule Histogrammar.Counted do
  defstruct entries: 0.0
end

defimpl Poison.Encoder, for: Histogrammar.Counted do
  def encode(%Histogrammar.Counted{} = counted, options) do
    Poison.Encoder.Map.encode(%{
      version: Histogrammar.specification_version,
      type: "Count",
      data: counted.entries
    }, options)
  end
end

defmodule Histogrammar.Count do
  alias Histogrammar.Counting
  alias Histogrammar.Counted

  def ing(transform \\ &(&1)) do
    %Counting{transform: transform}
  end

  def ed(entries) do
    %Counted{entries: entries}
  end

  def fill(%Counting{entries: entries, transform: transform} = counting, _datum, weight) when weight > 0,
  do: %{ counting | entries: entries + transform.(weight) }

  def fill(%Counting{} = counting, _datum, _weight), do: counting

  def combine(%Counting{entries: a}, %Counting{entries: b}), do: do_combine(a, b)
  def combine(%Counting{entries: a}, %Counted{entries: b}), do: do_combine(a, b)
  def combine(%Counted{entries: a}, %Counting{entries: b}), do: do_combine(a, b)
  def combine(%Counted{entries: a}, %Counted{entries: b}), do: do_combine(a, b)

  defp do_combine(a, b) when is_number(a) and is_number(b),
  do: %Counted{entries: a + b}
end
