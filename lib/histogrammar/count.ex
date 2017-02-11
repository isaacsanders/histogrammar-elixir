defmodule Histogrammar.Counting do
  defstruct transform: &Histogrammar.Util.identity/1,
            entries: 0.0
end

defimpl Poison.Encoder, for: Histogrammar.Counting do
  defdelegate encode(counting, options), to: Histogrammar.Count
end

defmodule Histogrammar.Counted do
  defstruct entries: 0.0
end

defimpl Poison.Encoder, for: Histogrammar.Counted do
  defdelegate encode(counted, options), to: Histogrammar.Count
end

defimpl Collectable, for: Histogrammar.Counting do
  def into(original), do: {original, Histogrammar.Primitive.collector_fun(Histogrammar.Count)}
end

defmodule Histogrammar.Count do
  alias Histogrammar.Counting
  alias Histogrammar.Counted

  @histogrammar_type "Count"

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

  def encode(struct, options) do
    Poison.Encoder.Map.encode(%{
      version: Histogrammar.specification_version,
      type: @histogrammar_type,
      data: encoder_data(struct)
    }, options)
  end

  def encoder_data(%Counting{} = counting), do: counting |> do_encoder_data
  def encoder_data(%Counted{} = counted), do: counted |> do_encoder_data

  defp do_encoder_data(%{entries: entries}), do: entries
end
