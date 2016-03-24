# Maxwell

Maxwell is an HTTP client which support for middleware and multiple adapters(ibrowse hackney...). It borrow idea from [tesla(elixir)](https://github.com/teamon/tesla) which base on [Faraday(ruby)](https://github.com/lostisland/faraday)

## Basic usage

## request example
```ex
iex> Maxwell.get(url: "http://httpbin.org/ip")
{:ok,
 %Maxwell{body: '{\n  "origin": "xx.xxx.xxx.xxx"\n}\n',
   headers: %{'Access-Control-Allow-Credentials' => 'true'},
   method: :get, opts: [], status: 200, url: "http://httpbin.org/ip"}}

iex> Maxwell.post!(url: "http://httpbin.org/post", body: "foo_body")
%Maxwell{body: '{\n  "args": {}, \n  "data": "foo_body_", \n  ...\n',
  headers: %{'Access-Control-Allow-Credentials' => 'true'},
  method: :post, opts: [], status: 200, url: "http://httpbin.org/post"}
```
> **Compare to using ibrowse's api **: [Compare Example](https://github.com/zhongwencool/maxwell/blob/master/examples/github_client.ex)
 
## Request parameters
```ex
[url:        request_url_string,
 headers:    request_headers_map,
 query:      request_query_map,
 body:       request_body_term,
 opts:       request_opts_keyword_list,
 respond_to: request_async_pid]
```
`h Maxwell.{method}` to see more information

## Reponse result 
```ex
{:ok,
  %Maxwell{
    headers: reponse_headers_map,
    status:  reponse_http_status_integer,
    body:    reponse_body_term,
    opts:    request_opts_keyword_list,
    url:     request_urlwithquery_string,    
  }}

# or
{:error, reason_term} 
  
```
## Creating API clients

Use `Maxwell.Builder` module to create API wrappers.

```ex
defmodule GitHub do
  # create get/1, get!/1  
  use Maxwell.Builder, ~w(get)a # or [:get]  or ["get"]
  
  middleware Maxwell.Middleware.BaseUrl, "https://api.github.com"
  middleware Maxwell.Middleware.Opts, [connect_timeout: 3000]
  middleware Maxwell.Middleware.Headers, %{'Content-Type': "application/vnd.github.v3+json", 'User-Agent': 'zhongwenool'}
  middleware Maxwell.Middleware.DecodeJson  

  adapter Maxwell.Adapter.Ibrowse

  def user_repos(login) do
    get(url: "/user/" <> login <> "/repos")
  end
end
```

Then use it like this:

```ex
GitHub.get(url: "/user/zhongwencool/repos")
GitHub.user_repos("zhonngwencool")
```

## Installation

  1. Add maxwell to your list of dependencies in `mix.exs`:
```ex
   def deps do
     [{:maxwell, github: "zhongwencool/maxwell", branch: master}]
   end
```
  2. Ensure maxwell is started before your application:
```ex
   def application do
      [applications: [:maxwell]] # also add your adapter here 
   end
```
## Adapters

Maxwell has support for different adapters that do the actual HTTP request processing.

### ibrowse

Maxwell has built-in support for [ibrowse](https://github.com/cmullaparthi/ibrowse) Erlang HTTP client.

To use it simply include `adapter Mawell.Adapter.Ibrowse` line in your API client definition.
global default adapter

```ex 
config :maxwell,
  default_adapter: Maxwell.Adapter.Ibrowse
```  

NOTE: Remember to include adapter(ibrowse) in applications list.

## Middleware

### Basic

- `Maxwell.Middleware.BaseUrl` - set base url for all request
- `Maxwell.Middleware.Headers` - set request headers
- `Maxwell.Middleware.Opts` - set options for all request
- `Maxwell.Middleware.DecodeRels` - decode reponse rels

### JSON
NOTE: default requires [poison](https://github.com/devinus/poison) as dependency

- `Maxwell.Middleware.EncodeJson` - endode request body as JSON, it will add %{'Content-Type': 'application/json'} to headers
- `Maxwell.Middleware.DecodeJson` - decode response body as JSON

Custom json library example 

```ex
middleware Maxwell.Middleware.EncodeJson &Poison.encode/1
middleware Maxwell.Middleware.DecodeJson &Poison.decode/1
```

## Writing your own middleware

A Maxwell middleware is a module with `call/3` function:

```ex
defmodule MyMiddleware do
  def call(env = %maxwell{}, run, options) do
    # ...     
  end
end
```
The arguments are:
- `env` - `%Maxwell{}` instance
- `run` - continuation function for the rest of middleware/adapter stack
- `options` - arguments passed during middleware configuration (`middleware MyMiddleware, options`)

There is no distinction between request and response middleware, it's all about executing `run` function at the correct time.

For example, request logger middleware could be implemented like this:

```ex
defmodule Maxwell.Middleware.RequestLogger do
  def call(env, run, _) do
    IO.inspect env # print request env
    run.(env)
  end
end
```

and response logger middleware like this:

```ex
defmodule Maxwell.Middleware.ResponseLogger do
  def call(env, run, _) do
    res = run.(env)
    IO.inspect res # print response env
    res
  end
end
```

## Asynchronous requests

If adapter supports it, you can make asynchronous requests by passing `respond_to: pid` option:

```ex

Maxwell.get(url: "http://example.org", respond_to: self)

receive do
  {:maxwell_response, res} -> res.status # => 200
end
```
## todo

- [] hackney adapter
- [] decode json when async 