defmodule Histogrammar.Util do
  def identity(x), do: x

  def min(a, b)
    when is_number(a) and is_number(b),
    do: Kernel.min(a, b)
  def min(a, nil) when is_number(a), do: a
  def min(nil, b) when is_number(b), do: b

  def max(a, b)
    when is_number(a) and is_number(b),
    do: Kernel.max(a, b)
  def max(a, nil) when is_number(a), do: a
  def max(nil, b) when is_number(b), do: b
end
