defprotocol Histogrammar.PresentTense do
  @type t() :: term()

  @spec fill(t(), term(), float()) :: t()
  def fill(present_tense, datum, weight)

  @spec to_past_tense(t()) :: Histogrammar.PastTense.t()
  def to_past_tense(present_tense)
end
