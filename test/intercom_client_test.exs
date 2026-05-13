defmodule Intercom.ClientTest do
  use ExUnit.Case

  setup do
    Req.Test.set_req_test_to_private(self())
    :ok
  end

  describe "auth/2" do
    test "builds Req-compatible basic auth options" do
      assert Intercom.Client.auth("app123", "token_xyz") == [
               auth: {:basic, "app123:token_xyz"}
             ]
    end

    test "handles a personal access token with empty api_key" do
      assert Intercom.Client.auth("personal_token", "") == [
               auth: {:basic, "personal_token:"}
             ]
    end
  end

  describe "get/3" do
    test "prepends the Intercom base URL to the path" do
      Req.Test.stub(IntercomStub, fn conn ->
        assert conn.host == "api.intercom.io"
        assert conn.request_path == "/users"
        Req.Test.json(conn, %{users: []})
      end)

      assert {:ok, %Req.Response{status: 200, body: %{"users" => []}}} =
               Intercom.Client.get("/users", [], plug: {Req.Test, IntercomStub})
    end

    test "sends default JSON accept and content-type headers" do
      Req.Test.stub(IntercomStub, fn conn ->
        assert Plug.Conn.get_req_header(conn, "accept") == ["application/json"]
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/json"]
        Req.Test.json(conn, %{})
      end)

      assert {:ok, %Req.Response{status: 200}} =
               Intercom.Client.get("/users", [], plug: {Req.Test, IntercomStub})
    end

    test "merges caller-supplied headers with defaults" do
      Req.Test.stub(IntercomStub, fn conn ->
        assert Plug.Conn.get_req_header(conn, "intercom-version") == ["2.11"]
        assert Plug.Conn.get_req_header(conn, "accept") == ["application/json"]
        Req.Test.json(conn, %{})
      end)

      assert {:ok, %Req.Response{status: 200}} =
               Intercom.Client.get(
                 "/users",
                 [{"intercom-version", "2.11"}],
                 plug: {Req.Test, IntercomStub}
               )
    end

    test "applies basic auth from auth/2" do
      Req.Test.stub(IntercomStub, fn conn ->
        assert ["Basic " <> encoded] = Plug.Conn.get_req_header(conn, "authorization")
        assert Base.decode64!(encoded) == "app_id:api_key"
        Req.Test.json(conn, %{})
      end)

      options =
        Intercom.Client.auth("app_id", "api_key") ++ [plug: {Req.Test, IntercomStub}]

      assert {:ok, %Req.Response{status: 200}} =
               Intercom.Client.get("/users", [], options)
    end
  end

  describe "post/4" do
    test "sends the body to the resolved URL" do
      Req.Test.stub(IntercomStub, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/users"
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert Jason.decode!(body) == %{"email" => "bob@bob.com"}
        Req.Test.json(conn, %{id: "u_1"})
      end)

      assert {:ok, %Req.Response{status: 200, body: %{"id" => "u_1"}}} =
               Intercom.Client.post(
                 "/users",
                 %{email: "bob@bob.com"},
                 [],
                 plug: {Req.Test, IntercomStub}
               )
    end

    test "round-trips an event with nested metadata" do
      payload = %{
        event_name: "purchased",
        created_at: 1_715_678_400,
        user_id: "u_42",
        metadata: %{
          order_id: "abc-123",
          items: ["sku-1", "sku-2"],
          amount: %{value: 1999, currency: "usd"}
        }
      }

      Req.Test.stub(IntercomStub, fn conn ->
        assert conn.request_path == "/events"
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert Jason.decode!(body) == %{
                 "event_name" => "purchased",
                 "created_at" => 1_715_678_400,
                 "user_id" => "u_42",
                 "metadata" => %{
                   "order_id" => "abc-123",
                   "items" => ["sku-1", "sku-2"],
                   "amount" => %{"value" => 1999, "currency" => "usd"}
                 }
               }

        conn |> Plug.Conn.put_status(202) |> Req.Test.json(%{})
      end)

      assert {:ok, %Req.Response{status: 202}} =
               Intercom.Client.post("/events", payload, [], plug: {Req.Test, IntercomStub})
    end

    test "sends a pre-encoded JSON binary body verbatim" do
      encoded = Jason.encode!(%{email: "bob@bob.com"})

      Req.Test.stub(IntercomStub, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == encoded
        Req.Test.json(conn, %{})
      end)

      assert {:ok, %Req.Response{status: 200}} =
               Intercom.Client.post("/users", encoded, [], plug: {Req.Test, IntercomStub})
    end

    test "round-trips a tag with a users array" do
      payload = %{
        name: "vip",
        users: [%{id: "u_1"}, %{id: "u_2"}, %{id: "u_3"}]
      }

      Req.Test.stub(IntercomStub, fn conn ->
        assert conn.request_path == "/tags"
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert Jason.decode!(body) == %{
                 "name" => "vip",
                 "users" => [
                   %{"id" => "u_1"},
                   %{"id" => "u_2"},
                   %{"id" => "u_3"}
                 ]
               }

        Req.Test.json(conn, %{id: "tag_1", name: "vip"})
      end)

      assert {:ok, %Req.Response{status: 200, body: %{"name" => "vip"}}} =
               Intercom.Client.post("/tags", payload, [], plug: {Req.Test, IntercomStub})
    end
  end

  describe "get!/3" do
    test "returns the response struct directly on success" do
      Req.Test.stub(IntercomStub, fn conn ->
        Req.Test.json(conn, %{users: []})
      end)

      assert %Req.Response{status: 200, body: %{"users" => []}} =
               Intercom.Client.get!("/users", [], plug: {Req.Test, IntercomStub})
    end

    test "raises on transport error" do
      Req.Test.stub(IntercomStub, fn conn ->
        Req.Test.transport_error(conn, :econnrefused)
      end)

      assert_raise Req.TransportError, fn ->
        Intercom.Client.get!("/users", [], plug: {Req.Test, IntercomStub}, retry: false)
      end
    end
  end
end
