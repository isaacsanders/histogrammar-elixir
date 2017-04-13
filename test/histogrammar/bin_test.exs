defmodule Histogrammar.BinTest do
  use ExUnit.Case
  use Quixir
  alias Histogrammar.Bin
  alias Histogrammar.Util
  alias Histogrammar.Sum
  alias Histogrammar.Average
  require Logger

  test :count_fill_in_bounds do
    ptest low: float(),
          high: float(min: ^low + 1.0),
          num: positive_int(),
          xs: list(of: float(min: ^low, max: ^high)) do
      Logger.info(inspect Enum.join(xs, ","))
      binning = Enum.into(xs, Bin.ing(num, low, high,
        overflow: Average.ing(&Util.identity/1),
        underflow: Average.ing(&Util.identity/1),
        nanflow: Average.ing(&Util.identity/1)))
      summing = Enum.into(binning.values, Sum.ing(fn (value) -> value.entries end))
      Logger.info inspect(binning, pretty: true)
      Logger.info inspect(summing, pretty: true)
      Logger.info inspect({binning.underflow.entries, 0.0})
      Logger.info inspect({binning.overflow.entries, 0.0})
      Logger.info inspect({binning.nanflow.entries, 0.0})
      Logger.info inspect({length(xs), trunc(summing.sum)})
      assert binning.underflow.entries == 0.0
      assert binning.overflow.entries == 0.0
      assert binning.nanflow.entries == 0.0
      assert length(xs) >= summing.sum
    end
  end
end
