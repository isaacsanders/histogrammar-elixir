defmodule Histogrammar do
  @ebin_path :code.lib_dir(:histogrammar, :ebin)

  def specification_version(), do: "1.0"

  def present_tense?(%{ __struct__: module }) do
    implmentations = Protocol.extract_impls(Histogrammar.PresentTense, [@ebin_path])
    module in implmentations
  end
  def present_tense?(_term), do: false

  def past_tense?(%{ __struct__: module }) do
    implmentations = Protocol.extract_impls(Histogrammar.PastTense, [@ebin_path])
    module in implmentations
  end
  def past_tense?(_term), do: false

  defdelegate fill(present_tense, datum, weight), to: Histogrammar.PresentTense
  defdelegate to_past_tense(present_tense), to: Histogrammar.PresentTense
  defdelegate combine(first, second), to: Histogrammar.PastTense
  defdelegate encoder_data(past_tense), to: Histogrammar.PastTense
end
