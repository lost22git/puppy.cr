module Puppy::Fetch
  CRLF                    = "\r\n"
  RESPONSE_BODY_MAX_SIZE  = 16 * (1024 * 1024)
  RESPONSE_BODY_INIT_SIZE = 8 * 1024

  class Error < Exception
  end

  # :nodoc:
  #
  macro dbg!(v)
    {% if !flag?(:release) %}
      print "[PuppyDebug] "
      pp! {{ v }}
    {% end %}
  end

  # To implement on diffenrent platform
  #
  # def self.fetch(req : HTTP::Request, decompress : Bool = true, timeout : Time::Span = 10.seconds, trust_all_certs : Bool = false, proxy_addr : String? = nil) : HTTP::Client::Response
  # end
end

{% if flag?(:windows) %}
  require "./windows/fetch"
{% else %}
  raise "No implementation for the platform"
{% end %}
