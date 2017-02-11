defmodule Histogrammar.Primitive do
  @type datum :: term()
  @type present_tense_form() :: Histogrammar.Counting.t
                              | Histogrammar.Summing.t
                              | Histogrammar.Averaging.t

  @type past_tense_form() :: Histogrammar.Counted.t
                           | Histogrammar.Summed.t
                           | Histogrammar.Averaged.t

  @type form() :: present_tense_form() | past_tense_form()

  @callback fill(present_tense_form(), datum(), float()) :: present_tense_form()
  @callback combine(form(), form()) :: form()

  def collector_fun(mod) do
    fn
      struct, {:cont, datum} -> mod.fill(struct, datum, 1.0)
      struct, :done -> struct
      _struct, :halt -> :ok
    end
  end
end
