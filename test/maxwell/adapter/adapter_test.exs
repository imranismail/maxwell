defmodule MaxwellAdapterTest do
  use ExUnit.Case

  alias Maxwell.Conn
  import Maxwell.Conn

  defmodule TestAdapter do
    def call(conn = %Conn{status: nil}) do
      {:ok, %{conn|status: 200,
              resp_headers: %{"Content-Type" => "text/plain"},
              resp_body: "testbody",
              state: :sent}}
    end
    def call(conn) do
      {:ok, %{conn| status: 400}}
    end
  end

  defmodule Client do
    use Maxwell.Builder
    adapter TestAdapter
  end

  test "return :status 200" do
    {:ok, result} = Client.get
    assert result |> Conn.get_status == 200
  end

  test "return :status 400" do
    assert_raise(Maxwell.Error, "url: \nmethod: get\nreason: :response_status_not_match\nmodule: Elixir.MaxwellAdapterTest.Client\n",
      fn() -> %Conn{status: 100} |> Client.get! end)
  end

  test "return resp content-type header" do
    {:ok, conn} = Client.get()
    assert conn |> get_resp_header == %{"Content-Type" => "text/plain"}
    assert conn |> get_resp_header("Content-Type") == "text/plain"
  end

  test "return resp_body" do
    {:ok, conn} = Client.get
    assert conn|> get_resp_body == "testbody"
    assert conn|> get_resp_body(&String.length/1) == 8
  end

  test "http method" do
    {:ok, conn} = Client.get
    conn1 = Client.get!
    assert Map.equal?(conn, conn1) == true
    assert conn1.method == :get
    {:ok, conn} = Client.head
    conn1 = Client.head!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :head
    {:ok, conn} = Client.post
    conn1 = Client.post!()
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :post
    {:ok, conn} = Client.put
    conn1 = Client.put!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :put
    {:ok, conn} = Client.patch
    conn1 = Client.patch!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :patch
    {:ok, conn} = Client.delete
    conn1 = Client.delete!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :delete
    {:ok, conn} = Client.trace
    conn1 = Client.trace!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :trace
    {:ok, conn} = Client.options
    conn1 = Client.options!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :options
  end

  test "path + query" do
    conn =
      "http://example.com"
      |> put_url
      |> put_path("/foo")
      |> put_query_string(%{a: 1, b: "foo"})
      |> Client.get!
    assert conn.url == "http://example.com"
    assert conn.path == "/foo"
    assert conn.query_string == %{a: 1, b: "foo"}
    assert Conn.get_status(conn) == 200
  end

end

