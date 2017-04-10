defmodule Histogrammar.Maximizing do
  defstruct quantity: nil,
            name: nil,
            entries: 0.0,
            max: nil

  defimpl Histogrammar.PresentTense, for: __MODULE__ do
    alias Histogrammar.Maximizing
    alias Histogrammar.Maximize
    alias Histogrammar.Util

    def fill(%Maximizing{} = maximizing, datum, weight) when weight > 0.0 do
      q = maximizing.quantity.(datum)
      do_fill(maximizing, weight, q)
    end
    def fill(%Maximizing{} = maximizing, _datum, _weight), do: maximizing

    defp do_fill(%Maximizing{entries: entries, max: current} = maximizing, weight, new),
      do: %{ maximizing | entries: entries + weight, max: Util.max(current, new) }

    def to_past_tense(%Maximizing{ entries: entries, max: max, name: name }) do
      Maximize.ed(entries, max, name)
    end
  end
end

defmodule Histogrammar.Maximized do
  defstruct entries: 0.0,
            max: nil,
            name: nil

  defimpl Histogrammar.PastTense, for: __MODULE__ do
    alias Histogrammar.Maximized
    alias Histogrammar.Maximize

    def combine(%Maximized{} = first,
                %Maximized{} = second) do
      name = if first.name == second.name, do: first.name, else: nil
      do_combine(first.entries + second.entries, first, second, name)
    end

    defp do_combine(entries, %Maximized{ max: nil }, b, name),
      do: Maximize.ed(entries, b.max, name)
    defp do_combine(entries, a, %Maximized{ max: nil }, name),
      do: Maximize.ed(entries, a.max, name)
    defp do_combine(entries, %Maximized{ max: first },
                             %Maximized{ max: second }, name),
      do: Maximize.ed(entries, max(first, second), name)

    def encoder_data(%Maximized{ entries: entries, max: max, name: nil}),
      do: %{ entries: entries, max: max }
    def encoder_data(%Maximized{ entries: entries, max: max, name: name }),
      do: %{ entries: entries, max: max, name: name }
  end
end

defmodule Histogrammar.Maximize do
  use Histogrammar.Primitive,
    histogrammar_type: "Maximize",
    present_tense: Histogrammar.Maximizing,
    past_tense: Histogrammar.Maximized

  def ing(quantity, name \\ nil) when is_function(quantity, 1) do
    %Histogrammar.Maximizing{quantity: quantity, name: name}
  end

  def ed(entries, max, name \\ nil)
  def ed(entries, max, name)
    when is_number(entries) and is_number(max),
    do: %Histogrammar.Maximized{entries: entries, max: max, name: name}
  def ed(0.0, nil, name),
    do: %Histogrammar.Maximized{entries: 0.0, max: nil, name: name}
end
