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

  defmacro __using__(histogrammar_type: histogrammar_type,
                     present_tense: present_tense,
                     past_tense: past_tense) do
    quote do
      defimpl Histogrammar.PastTense, for: unquote(present_tense) do
        @present_tense_impl Histogrammar.PresentTense.impl_for(struct(unquote(present_tense)))
        @past_tense_impl Histogrammar.PastTense.impl_for(struct(unquote(past_tense)))

        def combine(present_tense, %{ __struct__: unquote(present_tense) } = other_present_tense) do
          other = @present_tense_impl.to_past_tense(other_present_tense)
          combine(present_tense, other)
        end

        def combine(present_tense, %{ __struct__: unquote(past_tense) } = other) do
          present_tense
          |> @present_tense_impl.to_past_tense()
          |> @past_tense_impl.combine(other)
        end

        def encoder_data(present_tense) do
          present_tense
          |> @present_tense_impl.to_past_tense()
          |> @past_tense_impl.encoder_data()
        end
      end

      defimpl Collectable, for: unquote(present_tense) do
        @present_tense_impl Histogrammar.PresentTense.impl_for(struct(unquote(present_tense)))

        def into(present_tense) do
          {present_tense, &into_callback/2}
        end

        defp into_callback(struct, :done), do: struct
        defp into_callback(_struct, :halt), do: :ok
        defp into_callback(struct, {:cont, datum}),
          do: @present_tense_impl.fill(struct, datum, 1.0)
      end

      defimpl Poison.Encoder, for: unquote(past_tense) do
        @past_tense_impl Histogrammar.PastTense.impl_for(struct(unquote(past_tense)))

        def encode(past_tense, options) do
          Poison.Encoder.Map.encode(%{
            version: Histogrammar.specification_version,
            type: unquote(histogrammar_type),
            data: @past_tense_impl.encoder_data(past_tense)
          }, options)
        end
      end

      defimpl Poison.Encoder, for: unquote(present_tense) do
        @mixed_tense_impl Histogrammar.PastTense.impl_for(struct(unquote(present_tense)))

        def encode(present_tense, options) do
          Poison.Encoder.Map.encode(%{
            version: Histogrammar.specification_version,
            type: unquote(histogrammar_type),
            data: @mixed_tense_impl.encoder_data(present_tense)
          }, options)
        end
      end
    end
  end
end
