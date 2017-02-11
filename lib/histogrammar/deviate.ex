defmodule Histogrammar.Deviating do
  defstruct quantity: nil,
            name: nil,
            entries: 0.0,
            mean: nil,
            variance: nil
end

defimpl Poison.Encoder, for: Histogrammar.Deviating do
  defdelegate encode(deviating, options), to: Histogrammar.Deviate
end

defmodule Histogrammar.Deviated do
  @enforce_keys [:entries, :mean, :variance, :name]
  defstruct [:entries, :mean, :variance, :name]
end

defimpl Poison.Encoder, for: Histogrammar.Deviated do
  defdelegate encode(deviated, options), to: Histogrammar.Deviate
end

defimpl Collectable, for: Histogrammar.Deviating do
  def into(original), do: {original, Histogrammar.Primitive.collector_fun(Histogrammar.Deviate)}
end

defmodule Histogrammar.Deviate do
  alias Histogrammar.Deviating
  alias Histogrammar.Deviated

  @histogrammar_type "Deviate"

  def fill(%Deviating{} = deviating, datum, weight) when is_number(weight) and weight > 0.0 do
      q = deviating.quantity.(datum)
      {mean, variance} = if deviating.entries == 0.0, do: {0.0, 0.0}, else: {deviating.mean, deviating.variance}
      variance_times_entries = variance * deviating.entries
      entries = deviating.entries + weight
      {mean, variance_times_entries} = if is_nil(mean) or is_nil(q), do: {nil, nil}, else: {mean, variance_times_entries}


      delta = q - mean
      shift = delta * weight / entries
      mean = mean + shift
      variance_times_entries = variance_times_entries + weight * delta * (q - mean)

      %{ deviating | entries: entries, mean: mean, variance: variance_times_entries / entries }
  end
  def fill(%Deviating{} = deviating, _datum, weight) when is_number(weight), do: deviating

  def combine(%Deviating{} = a, %Deviating{} = b), do: do_combine(a, b)
  def combine(%Deviating{} = a, %Deviated{} = b), do: do_combine(a, b)
  def combine(%Deviated{} = a, %Deviating{} = b), do: do_combine(a, b)
  def combine(%Deviated{} = a, %Deviated{} = b), do: do_combine(a, b)
  def do_combine(a, b) do
    name = if a.name == b.name, do: a.name, else: nil
    case {a.entries, b.entries} do
      {0.0, 0.0} -> %Deviated{entries: 0.0, mean: nil, variance: nil, name: name}
      {_, 0.0} -> a
      {0.0, _} -> b
      _ ->
        entries = a.entries + b.entries
        mean = (a.entries * a.mean + b.entries * b.mean) / entries
        variance_times_entries = a.entries * a.variance +
          b.entries * b.variance +
          a.entries * :math.pow(a.mean, 2) +
          b.entries * :math.pow(b.mean, 2) -
          2.0 * mean * (a.entries * a.mean + b.entries * b.mean) + entries * :math.pow(mean, 2)
        ed(entries, mean, variance_times_entries / entries)
    end
  end

  def ing(quantity, name \\ nil) when is_function(quantity, 1) do
    %Deviating{quantity: quantity, name: name}
  end

  def ed(entries, mean, variance, name \\ nil) when
  is_number(entries) and
  is_number(mean) and
  is_number(variance) do
    %Deviated{entries: entries, mean: mean, variance: variance, name: name}
  end

  def encode(struct, options) do
    Poison.Encoder.Map.encode(%{
      version: Histogrammar.specification_version,
      type: @histogrammar_type,
      data: encoder_data(struct)
    }, options)
  end

  def encoder_data(%Deviating{} = deviating), do: deviating |> Map.from_struct |> do_encoder_data
  def encoder_data(%Deviated{} = deviated), do: deviated |> Map.from_struct |> do_encoder_data

  defp do_encoder_data(%{ name: nil } = data), do: Map.take(data, [:mean, :variance, :entries])
  defp do_encoder_data(data), do: Map.take(data, [:mean, :variance, :entries, :name])
end
