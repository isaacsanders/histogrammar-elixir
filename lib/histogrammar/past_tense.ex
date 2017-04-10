defprotocol Histogrammar.PastTense do
  @type t() :: term()

  @spec combine(t(), t()) :: {:ok, t()}
                           | {:error, :aggregator_mismatch}
  def combine(a, b)

  @spec encoder_data(t()) :: term()
  def encoder_data(past_tense)
end

