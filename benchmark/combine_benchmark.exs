alias Histogrammar.Deviate
alias Histogrammar.Deviated

defmodule CombineBenchmark do
  defdelegate current(a, b), to: Histogrammar.PastTense, as: :combine

  def original(%Deviated{} = a, %Deviated{} = b) do
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
        2.0 * mean * (a.entries * a.mean + b.entries * b.mean) +
        entries * :math.pow(mean, 2)
        Histogrammar.Deviate.ed(entries, mean, variance_times_entries / entries, name)
    end
  end
end

stream = Stream.repeatedly(fn ->
  Deviate.ed(:rand.uniform(1_000_000), :rand.uniform(), :rand.uniform())
end)

list = Enum.take(stream, 100_000)

Benchee.run(%{
  "original" => fn ->
    Enum.reduce(list, fn (a, b) ->
      CombineBenchmark.original(a, b)
    end)
  end,
  "current" => fn ->
    Enum.reduce(list, fn (a, b) ->
      CombineBenchmark.current(a, b)
    end)
  end
}, parallel: 16, time: 30)
