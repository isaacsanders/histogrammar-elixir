defmodule Histogrammar.Averaging do
  defstruct quantity: nil,
            name: nil,
            entries: 0.0,
            mean: nil
end

defimpl Poison.Encoder, for: Histogrammar.Averaging do
  defdelegate encode(averaging, options), to: Histogrammar.Average
end

defmodule Histogrammar.Averaged do
  @enforce_keys [:entries, :mean, :name]
  defstruct [:entries, :mean, :name]
end

defimpl Poison.Encoder, for: Histogrammar.Averaged do
  defdelegate encode(averaged, options), to: Histogrammar.Average
end

defimpl Collectable, for: Histogrammar.Averaging do
  def into(original), do: {original, Histogrammar.Primitive.collector_fun(Histogrammar.Average)}
end

defmodule Histogrammar.Average do
  alias Histogrammar.Averaging
  alias Histogrammar.Averaged

  @histogrammar_type "Average"

  def fill(%Averaging{} = averaging, datum, weight) when is_number(weight) and weight > 0.0 do
      q = averaging.quantity.(datum)
      mean = if averaging.entries == 0.0, do: 0.0, else: averaging.mean
      entries = averaging.entries + weight
      mean = if is_nil(mean) or is_nil(q), do: nil, else: mean

      delta = q - mean
      shift = delta * weight / entries

      %{ averaging | entries: entries, mean: mean + shift }
  end
  def fill(%Averaging{} = averaging, _datum, weight) when is_number(weight), do: averaging

  def combine(%Averaging{} = a, %Averaging{} = b), do: do_combine(a, b)
  def combine(%Averaging{} = a, %Averaged{} = b), do: do_combine(a, b)
  def combine(%Averaged{} = a, %Averaging{} = b), do: do_combine(a, b)
  def combine(%Averaged{} = a, %Averaged{} = b), do: do_combine(a, b)
  def do_combine(a, b) do
    name = if a.name == b.name, do: a.name, else: nil
    entries = a.entries + b.entries
    case {entries, b.entries} do
      {0.0, 0.0} -> %Averaged{entries: 0.0, mean: nil, name: name}
      {_, 0.0} -> a
      {^entries, ^entries} -> b
      _ ->
        ed(entries, (a.entries * a.mean + b.entries * b.mean) / entries)
    end
  end

  def ing(quantity, name \\ nil) when is_function(quantity, 1) do
    %Averaging{quantity: quantity, name: name}
  end

  def ed(entries, mean, name \\ nil) when is_number(entries) and is_number(mean) do
    %Averaged{entries: entries, mean: mean, name: name}
  end

  def encode(struct, options) do
    Poison.Encoder.Map.encode(%{
      version: Histogrammar.specification_version,
      type: @histogrammar_type,
      data: encoder_data(struct)
    }, options)
  end

  defp encoder_data(%Averaging{} = averaging), do: averaging |> Map.from_struct |> do_encoder_data
  defp encoder_data(%Averaged{} = averaged), do: averaged |> Map.from_struct |> do_encoder_data

  defp do_encoder_data(%{ name: name } = data) when is_nil(name), do: Map.take(data, [:mean, :entries])
  defp do_encoder_data(data), do: Map.take(data, [:mean, :entries, :name])
end
