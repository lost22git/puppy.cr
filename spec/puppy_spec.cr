require "./spec_helper"
require "json"

describe Puppy do
  it "gzip" do
    # curl -X GET "https://httpbin.org/gzip" -H  "accept: application/json"
    #
    headers = HTTP::Headers.new
    headers["accept-encoding"] = "gzip"
    headers["content-type"] = "application/json"
    url = "https://httpbin.org/gzip"
    method = "GET"
    req = HTTP::Request.new method, url, headers: headers

    resp = Puppy.fetch req, 10.seconds
    JSON.parse(resp.body_io)["gzipped"].as_bool.should be_true
  end

  # Failed both WinHttp and crystal std Compress::Deflate::Reader
  #
  # trace: https://github.com/crystal-lang/crystal/issues/5221
  #
  # it "deflate" do
  #   # curl -X GET "https://httpbin.org/deflate" -H  "accept: application/json"
  #   #
  #   headers = HTTP::Headers.new
  #   headers["content-type"] = "application/json"
  #   url = "https://httpbin.org/deflate"
  #   method = "GET"
  #   req = HTTP::Request.new method, url, headers: headers

  #   resp = Puppy.fetch req, 10.seconds
  #   JSON.parse(resp.body_io)["deflated"].as_bool.should be_true
  # end

  it "status code" do
    # curl -X GET "https://httpbin.org/status/444" -H  "accept: text/plain"
    #
    headers = HTTP::Headers.new
    headers["accept-encoding"] = "gzip"
    url = "https://httpbin.org/status/444"
    method = "GET"
    req = HTTP::Request.new method, url, headers: headers

    resp = Puppy.fetch req, 10.seconds
    resp.status_code.should eq 444
  end

  # comment it when running on github action
  #
  # it "proxy" do
  #   # curl -X GET "https://httpbin.org/ip" -H  "accept: application/json"
  #   #
  #   headers = HTTP::Headers.new
  #   headers["accept"] = "application/json"
  #   url = "https://httpbin.org/ip"
  #   method = "GET"
  #   req = HTTP::Request.new method, url, headers

  #   # proxy
  #   resp = Puppy.fetch req, 10.seconds, proxy_addr: URI.parse("http://localhost:55556")
  #   proxied_pub_ip = JSON.parse(resp.body_io)["origin"].as_s
  #   proxied_pub_ip.should_not be ""

  #   # no proxy
  #   resp = Puppy.fetch req, 10.seconds
  #   no_proxied_pub_ip = JSON.parse(resp.body_io)["origin"].as_s
  #   no_proxied_pub_ip.should_not be ""
  #   no_proxied_pub_ip.should_not eq proxied_pub_ip
  # end

  it "user-agent" do
    # curl -X GET "https://httpbin.org/user-agent" -H  "accept: application/json"
    #
    headers = HTTP::Headers.new
    headers["accept"] = "application/json"
    url = "https://httpbin.org/user-agent"
    method = "GET"
    req = HTTP::Request.new method, url, headers

    resp = Puppy.fetch req, 10.seconds
    ua = JSON.parse(resp.body_io)["user-agent"].as_s
    ua.should eq Puppy::UA

    # use custom UA
    headers["user-agent"] = ";-)"
    req = HTTP::Request.new method, url, headers

    resp = Puppy.fetch req, 10.seconds
    ua = JSON.parse(resp.body_io)["user-agent"].as_s
    ua.should eq ";-)"
  end

  it "large file download" do
    # curl -X GET "https://httpbin.org/bytes/100" -H  "accept: application/octet-stream"
    #
    headers = HTTP::Headers.new
    headers["accept"] = "application/octet-stream"
    url = "https://httpbin.org/bytes/" + (10 * 1024 * 1024).to_s
    method = "GET"
    req = HTTP::Request.new method, url, headers

    resp = Puppy.fetch req, 10.seconds
    resp.body_io.getb_to_end.size.should eq(100 * 1024) # httpbin only generate up to 100KB data
  end

  # it "timeout" do
  #   # curl -X GET "https://httpbin.org/delay/5" -H  "accept: application/json"
  #   #
  #   headers = HTTP::Headers.new
  #   headers["accept"] = "application/json"
  #   url = "https://httpbin.org/delay/5"
  #   method = "GET"
  #   req = HTTP::Request.new method, url, headers

  #   resp = Puppy.fetch req, 1.seconds
  # end
end
