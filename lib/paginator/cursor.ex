defmodule Paginator.Cursor do
  @moduledoc false
  def decode(nil), do: nil

  def decode(encoded_cursor) do
    encoded_cursor
    |> Base.url_decode64!()
    |> safe_binary_to_term()
    |> Enum.map(&Paginator.Cursor.Decode.convert/1)
  end

  def encode(values) when is_list(values) do
    values
    |> Enum.map(&Paginator.Cursor.Encode.convert/1)
    |> safe_term_to_binary()
    |> Base.url_encode64()
  end

  def encode(value) do
    encode([value])
  end

  # Adapted from https://github.com/elixir-plug/plug_crypto/blob/f53977806ab4ee82850fb11fd552a663b60e12ab/lib/plug/crypto.ex#L27
  @spec safe_binary_to_term(binary()) :: term()
  def safe_binary_to_term(binary) when is_binary(binary) do
    term = :erlang.binary_to_term(binary, [:safe])
    safe_terms(term)
    term
  end

  def safe_term_to_binary(term) do
    safe_terms(term)
    :erlang.term_to_binary(term)
  end

  defp safe_terms(list) when is_list(list) do
    safe_list(list)
  end

  defp safe_terms(tuple) when is_tuple(tuple) do
    safe_tuple(tuple, tuple_size(tuple))
  end

  defp safe_terms(map) when is_map(map) do
    folder = fn key, value, acc ->
      safe_terms(key)
      safe_terms(value)
      acc
    end

    :maps.fold(folder, map, map)
  end

  defp safe_terms(other)
       when is_atom(other) or is_number(other) or is_bitstring(other) or is_pid(other) or
              is_reference(other) do
    other
  end

  defp safe_terms(other) do
    raise ArgumentError,
          "cannot deserialize #{inspect(other)}, the term is not safe for deserialization"
  end

  defp safe_list([]), do: :ok

  defp safe_list([h | t]) when is_list(t) do
    safe_terms(h)
    safe_list(t)
  end

  defp safe_list([h | t]) do
    safe_terms(h)
    safe_terms(t)
  end

  defp safe_tuple(_tuple, 0), do: :ok

  defp safe_tuple(tuple, n) do
    safe_terms(:erlang.element(n, tuple))
    safe_tuple(tuple, n - 1)
  end
end

defprotocol Paginator.Cursor.Encode do
  @fallback_to_any true

  def convert(term)
end

defprotocol Paginator.Cursor.Decode do
  @fallback_to_any true

  def convert(term)
end

defimpl Paginator.Cursor.Encode, for: Any do
  def convert(term), do: term
end

defimpl Paginator.Cursor.Decode, for: Any do
  def convert(term), do: term
end
