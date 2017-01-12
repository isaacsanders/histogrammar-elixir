defmodule Histogrammar.Summing do
  defstruct quantity: nil,
            name: nil,
            entries: 0.0,
            sum: 0.0
end

defimpl Poison.Encoder, for: Histogrammar.Summing do
  def encode(%Histogrammar.Summing{} = summing, options) do
    data = if is_nil(summing.name) do
      %{ sum: summing.sum, entries: summing.entries, }
    else
      %{ sum: summing.sum, entries: summing.entries, name: summing.name, }
    end
    Poison.Encoder.Map.encode(%{
      version: Histogrammar.specification_version,
      type: "Sum",
      data: data
    }, options)
  end
end

defmodule Histogrammar.Summed do
  @enforce_keys [:entries, :sum, :name]
  defstruct [:entries, :sum, :name]
end

defimpl Poison.Encoder, for: Histogrammar.Summed do
  def encode(%Histogrammar.Summed{} = summed, options) do
    data = if is_nil(summed.name) do
      %{ sum: summed.sum, entries: summed.entries, }
    else
      %{ sum: summed.sum, entries: summed.entries, name: summed.name, }
    end
    Poison.Encoder.Map.encode(%{
      version: Histogrammar.specification_version,
      type: "Sum",
      data: data
    }, options)
  end
end

defmodule Histogrammar.Sum do
  alias Histogrammar.Summing
  alias Histogrammar.Summed

  def fill(%Summing{entries: entries, sum: sum} = summing, datum, weight) when is_number(weight) and weight > 0.0 do
      q = summing.quantity.(datum)
      %{ summing | entries: entries + weight, sum: sum + q }
  end
  def fill(%Summing{} = summing, datum, weight) when is_number(weight), do: summing

  def combine(%Summing{} = a, %Summing{} = b), do: do_combine(a, b)
  def combine(%Summing{} = a, %Summed{} = b), do: do_combine(a, b)
  def combine(%Summed{} = a, %Summing{} = b), do: do_combine(a, b)
  def combine(%Summed{} = a, %Summed{} = b), do: do_combine(a, b)
  def do_combine(a, b) do
    ed(a.entries + b.entries, a.sum + b.sum)
  end

  def ing(quantity, name \\ nil) when is_function(quantity, 1) do
    %Summing{quantity: quantity, name: name}
  end

  def ed(entries, sum, name \\ nil) when is_number(entries) and is_number(sum) do
    %Summed{entries: entries, sum: sum, name: name}
  end
end
