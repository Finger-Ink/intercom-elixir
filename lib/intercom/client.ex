defmodule Intercom.Client do
  use HTTPoison.Base

  def process_request_headers(headers) do
    headers ++ [
      Accept: "application/json",
      "Content-Type": "application/json"
    ]
  end

  def process_url(url) do
    "https://api.intercom.io" <> url
  end

  def auth(app_id, api_key) do
    [basic_auth: {app_id, api_key}]
  end
end
