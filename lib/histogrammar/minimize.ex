defmodule Histogrammar.Minimizing do
  defstruct quantity: nil,
            name: nil,
            entries: 0.0,
            min: nil

  defimpl Histogrammar.PresentTense, for: __MODULE__ do
    alias Histogrammar.Minimizing
    alias Histogrammar.Minimize

    def fill(%Minimizing{} = minimizing, datum, weight) when weight > 0.0 do
      q = minimizing.quantity.(datum)
      do_fill(minimizing, weight, q)
    end
    def fill(%Minimizing{} = minimizing, _datum, _weight), do: minimizing

    defp do_fill(%Minimizing{entries: entries, min: current} = minimizing, weight, new),
      do: %{ minimizing | entries: entries + weight, min: min(current, new) }

    def to_past_tense(%Minimizing{ entries: entries, min: min, name: name }) do
      Minimize.ed(entries, min, name)
    end
  end
end

defmodule Histogrammar.Minimized do
  defstruct entries: 0.0,
            min: nil,
            name: nil

  defimpl Histogrammar.PastTense, for: __MODULE__ do
    alias Histogrammar.Minimized
    alias Histogrammar.Minimize
    alias Histogrammar.Util

    def combine(%Minimized{} = first,
                %Minimized{} = second) do
      name = if first.name == second.name, do: first.name, else: nil
      do_combine(first.entries + second.entries, first, second, name)
    end

    defp do_combine(entries, %Minimized{ min: nil }, b, name),
      do: Minimize.ed(entries, b.min, name)
    defp do_combine(entries, a, %Minimized{ min: nil }, name),
      do: Minimize.ed(entries, a.min, name)
    defp do_combine(entries, %Minimized{ min: first },
                             %Minimized{ min: second }, name),
      do: Minimize.ed(entries, Util.min(first, second), name)

    def encoder_data(%Minimized{ entries: entries, min: min, name: nil}),
      do: %{ entries: entries, min: min }
    def encoder_data(%Minimized{ entries: entries, min: min, name: name }),
      do: %{ entries: entries, min: min, name: name }
  end
end

defmodule Histogrammar.Minimize do
  use Histogrammar.Primitive,
    histogrammar_type: "Minimize",
    present_tense: Histogrammar.Minimizing,
    past_tense: Histogrammar.Minimized

  def ing(quantity, name \\ nil) when is_function(quantity, 1) do
    %Histogrammar.Minimizing{quantity: quantity, name: name}
  end

  def ed(entries, min, name \\ nil)
  def ed(entries, min, name)
    when is_number(entries) and is_number(min),
    do: %Histogrammar.Minimized{entries: entries, min: min, name: name}
  def ed(0.0, nil, name),
    do: %Histogrammar.Minimized{entries: 0.0, min: nil, name: name}
end
