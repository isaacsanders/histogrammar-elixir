defmodule Histogrammar.Deviating do
  defstruct quantity: nil,
            name: nil,
            entries: 0.0,
            mean: nil,
            variance: nil

  defimpl Histogrammar.PresentTense, for: __MODULE__ do
    alias Histogrammar.Deviating

    def fill(%Deviating{} = deviating, datum, weight) when weight > 0.0 do
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
    def fill(%Deviating{} = deviating, _datum, _weight), do: deviating

    def to_past_tense(%Deviating{ entries: entries, mean: mean, variance: variance, name: name }) do
      Histogrammar.Deviate.ed(entries, mean, variance, name)
    end
  end
end

defmodule Histogrammar.Deviated do
  defstruct entries: 0.0,
            mean: nil,
            variance: nil,
            name: nil

  defimpl Histogrammar.PastTense, for: __MODULE__ do
    alias Histogrammar.Deviated

    def combine(%Deviated{} = a, %Deviated{} = b) do
      name = if a.name == b.name, do: a.name, else: nil
      case {a.entries, b.entries} do
        {0.0, 0.0} -> %Deviated{entries: 0.0, mean: nil, variance: nil, name: name}
        {_, 0.0} -> a
        {0.0, _} -> b
        _ ->
          entries = a.entries + b.entries
          a_sum = a.entries * a.mean
          b_sum = b.entries * b.mean
          sum = a_sum + b_sum

          mean = sum / entries

          variance_times_entries =
            a.entries * a.variance +
            b.entries * b.variance +
            a_sum * a.mean +
            b_sum * b.mean -
            sum * mean
          Histogrammar.Deviate.ed(entries, mean, variance_times_entries / entries, name)
      end
    end

    def encoder_data(%Deviated{ entries: entries, mean: mean, variance: variance, name: nil}),
      do: %{ entries: entries, mean: mean, variance: variance }
    def encoder_data(%Deviated{ entries: entries, mean: mean, variance: variance, name: name }),
      do: %{ entries: entries, mean: mean, variance: variance, name: name }
  end
end

defmodule Histogrammar.Deviate do
  use Histogrammar.Primitive,
    histogrammar_type: "Deviate",
    present_tense: Histogrammar.Deviating,
    past_tense: Histogrammar.Deviated

  def ing(quantity, name \\ nil) when is_function(quantity, 1) do
    %Histogrammar.Deviating{quantity: quantity, name: name}
  end

  @spec ed(Histogrammar.entries(),
           Histogrammar.float(),
           Histogrammar.float(),
           Histogrammar.name()) :: Histogrammar.Deviated.t()
  def ed(entries, mean, variance, name \\ nil)
  def ed(entries, mean, variance, name)
    when is_number(entries) and is_number(mean) and is_number(variance),
    do: %Histogrammar.Deviated{entries: entries, mean: mean, variance: variance, name: name}
  def ed(0.0, nil, nil, name),
    do: %Histogrammar.Deviated{entries: 0.0, mean: nil, variance: nil, name: name}
end
