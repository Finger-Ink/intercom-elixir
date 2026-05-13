defmodule Intercom.Client do
  @base_url "https://api.intercom.io"

  @default_headers [
    {"accept", "application/json"},
    {"content-type", "application/json"}
  ]

  def auth(app_id, api_key) do
    [auth: {:basic, "#{app_id}:#{api_key}"}]
  end

  def get(url, headers \\ [], options \\ []),
    do: request(:get, url, nil, headers, options)

  def get!(url, headers \\ [], options \\ []),
    do: request!(:get, url, nil, headers, options)

  def post(url, body, headers \\ [], options \\ []),
    do: request(:post, url, body, headers, options)

  def post!(url, body, headers \\ [], options \\ []),
    do: request!(:post, url, body, headers, options)

  def put(url, body, headers \\ [], options \\ []),
    do: request(:put, url, body, headers, options)

  def put!(url, body, headers \\ [], options \\ []),
    do: request!(:put, url, body, headers, options)

  def patch(url, body, headers \\ [], options \\ []),
    do: request(:patch, url, body, headers, options)

  def patch!(url, body, headers \\ [], options \\ []),
    do: request!(:patch, url, body, headers, options)

  def delete(url, headers \\ [], options \\ []),
    do: request(:delete, url, nil, headers, options)

  def delete!(url, headers \\ [], options \\ []),
    do: request!(:delete, url, nil, headers, options)

  def head(url, headers \\ [], options \\ []),
    do: request(:head, url, nil, headers, options)

  def head!(url, headers \\ [], options \\ []),
    do: request!(:head, url, nil, headers, options)

  defp request(method, url, body, headers, options) do
    [method: method, url: url, base_url: @base_url, headers: @default_headers ++ headers]
    |> maybe_put_body(body)
    |> Keyword.merge(options)
    |> Req.request()
  end

  defp request!(method, url, body, headers, options) do
    case request(method, url, body, headers, options) do
      {:ok, response} -> response
      {:error, error} -> raise error
    end
  end

  defp maybe_put_body(opts, nil), do: opts
  defp maybe_put_body(opts, body) when is_binary(body), do: Keyword.put(opts, :body, body)
  defp maybe_put_body(opts, body) when is_list(body), do: Keyword.put(opts, :body, body)
  defp maybe_put_body(opts, body), do: Keyword.put(opts, :json, body)
end
