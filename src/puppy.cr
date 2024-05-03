require "http/request"
require "http/client/response"
require "http/headers"

require "./puppy/fetch"

module Puppy
  # Executes a request.
  # The response will have its body_io as a `IO`, accessed via `HTTP::Client::Response#body_io`.
  #
  # ```
  # require "puppy"
  # request = HTTP::Request.new "GET", "https://www.example.com"
  # response = Puppy.exec(request, decompress: true, timeout: 10.seconds, trust_all_certs: false, proxy_addr: "http://proxy_host:proxy_prort")
  # response.body # => "..."
  # ```
  def self.exec(request : HTTP::Request, decompress : Bool = true, timeout : Time::Span = 10.seconds, trust_all_certs : Bool = false, proxy_addr : String? = nil) : HTTP::Client::Response
    Fetch.fetch request, decompress, timeout, trust_all_certs, proxy_addr
  end

  {% for method in %w(get post put head delete patch options) %}
    # Executes a {{method.id.upcase}} request.
    # The response will have its body_io as a `IO`, accessed via `HTTP::Client::Response#body_io`.
    #
    # ```
    # require "puppy"
    #
    # response = Puppy.{{method.id}}("https://www.example.com", headers: HTTP::Headers{"User-Agent" => "AwesomeApp"}, body: "Hello!")
    # response.body #=> "..."
    # ```
    def self.{{method.id}}(path : String, headers : HTTP::Headers? = nil, body : IO | Bytes | String | Nil = nil,decompress : Bool = true, timeout : Time::Span = 10.seconds, trust_all_certs : Bool = false, proxy_addr : String? = nil) : HTTP::Client::Response
      request = HTTP::Request.new {{ method.upcase }}, path, headers, body
      exec request, decompress, timeout, trust_all_certs, proxy_addr
    end

    # Executes a {{method.id.upcase}} request with form data and returns a `Response`. The "Content-Type" header is set
    # to "application/x-www-form-urlencoded".
    #
    # ```
    # require "puppy"
    #
    # response = Puppy.{{method.id}} "https://www.example.com", form: "foo=bar"
    # ```
    def self.{{method.id}}(path, headers : HTTP::Headers? = nil, *, form : String | IO, decompress : Bool = true, timeout : Time::Span = 10.seconds, trust_all_certs : Bool = false, proxy_addr : String? = nil) : HTTP::Client::Response
      request = HTTP::Request.new {{ method.upcase }}, path, headers, form
      request.headers["Content-Type"] = "application/x-www-form-urlencoded"
      exec request, decompress, timeout, trust_all_certs, proxy_addr
    end

    # Executes a {{method.id.upcase}} request with form data and returns a `Response`. The "Content-Type" header is set
    # to "application/x-www-form-urlencoded".
    #
    # ```
    # require "puppy"
    #
    # response = Puppy.{{method.id}} "https://www.example.com", form: {"foo" => "bar"}
    # ```
    def self.{{method.id}}(path, headers : HTTP::Headers? = nil, *, form : Hash(String, String) | NamedTuple, decompress : Bool = true, timeout : Time::Span = 10.seconds, trust_all_certs : Bool = false, proxy_addr : String? = nil) : HTTP::Client::Response
      body = URI::Params.encode(form)
      {{method.id}} path, form: body, headers: headers, decompress: decompress, timeout: timeout, trust_all_certs: trust_all_certs, proxy_addr: proxy_addr
    end
  {% end %}
end
