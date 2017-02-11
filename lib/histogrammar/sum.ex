defmodule Histogrammar.Summing do
  defstruct quantity: nil,
            name: nil,
            entries: 0.0,
            sum: 0.0
end

defimpl Poison.Encoder, for: Histogrammar.Summing do
  defdelegate encode(summing, options), to: Histogrammar.Sum
end

defmodule Histogrammar.Summed do
  @enforce_keys [:entries, :sum, :name]
  defstruct [:entries, :sum, :name]
end

defimpl Poison.Encoder, for: Histogrammar.Summed do
  defdelegate encode(summed, options), to: Histogrammar.Sum
end

defimpl Collectable, for: Histogrammar.Summing do
  def into(original), do: {original, Histogrammar.Primitive.collector_fun(Histogrammar.Sum)}
end

defmodule Histogrammar.Sum do
  alias Histogrammar.Summing
  alias Histogrammar.Summed

  @histogrammar_type "Sum"

  def fill(%Summing{entries: entries, sum: sum} = summing, datum, weight) when is_number(weight) and weight > 0.0 do
      q = summing.quantity.(datum)
      %{ summing | entries: entries + weight, sum: sum + q }
  end
  def fill(%Summing{} = summing, _datum, weight) when is_number(weight), do: summing

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

  def encode(struct, options) do
    Poison.Encoder.Map.encode(%{
      version: Histogrammar.specification_version,
      type: @histogrammar_type,
      data: encoder_data(struct)
    }, options)
  end

  def encoder_data(%Summing{} = summing), do: summing |> Map.from_struct |> do_encoder_data
  def encoder_data(%Summed{} = summed), do: summed |> Map.from_struct |> do_encoder_data

  defp do_encoder_data(%{ name: name } = data) when is_nil(name), do: Map.take(data, [:sum, :entries])
  defp do_encoder_data(data), do: Map.take(data, [:sum, :entries, :name])
end
