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

    resp = Puppy.get url, headers
    JSON.parse(resp.body_io)["gzipped"].as_bool.should be_true
  end

  it "deflate" do
    # curl -X GET "https://httpbin.org/deflate" -H  "accept: application/json"
    #
    headers = HTTP::Headers.new
    headers["content-type"] = "application/json"
    url = "https://httpbin.org/deflate"

    resp = Puppy.get url, headers
    JSON.parse(resp.body_io)["deflated"].as_bool.should be_true
  end

  it "status code" do
    # curl -X GET "https://httpbin.org/status/444" -H  "accept: text/plain"
    #
    url = "https://httpbin.org/status/444"

    resp = Puppy.get url
    resp.status_code.should eq 444
  end

  # # comment it when running on github action
  # #
  # it "proxy" do
  #  # curl -X GET "https://httpbin.org/ip" -H  "accept: application/json"
  #  #
  #  headers = HTTP::Headers.new
  #  headers["accept"] = "application/json"
  #  url = "https://httpbin.org/ip"

  #  # proxy
  #  resp = Puppy.get url, headers, proxy_addr: "http://localhost:55556"
  #  proxied_pub_ip = JSON.parse(resp.body_io)["origin"].as_s
  #  proxied_pub_ip.should_not be ""

  #  # no proxy
  #  resp = Puppy.get url, headers
  #  no_proxied_pub_ip = JSON.parse(resp.body_io)["origin"].as_s
  #  no_proxied_pub_ip.should_not be ""
  #  no_proxied_pub_ip.should_not eq proxied_pub_ip
  # end

  it "user-agent" do
    # curl -X GET "https://httpbin.org/user-agent" -H  "accept: application/json"
    #
    headers = HTTP::Headers.new
    headers["accept"] = "application/json"
    url = "https://httpbin.org/user-agent"

    resp = Puppy.get url, headers
    ua = JSON.parse(resp.body_io)["user-agent"].as_s
    ua.should eq Puppy::UA

    # use custom UA
    headers["user-agent"] = ";-)"

    resp = Puppy.get url, headers
    ua = JSON.parse(resp.body_io)["user-agent"].as_s
    ua.should eq ";-)"
  end

  it "large file download" do
    # curl -X GET "https://httpbin.org/bytes/100" -H  "accept: application/octet-stream"
    #
    headers = HTTP::Headers.new
    headers["accept"] = "application/octet-stream"
    url = "https://httpbin.org/bytes/" + (10 * 1024 * 1024).to_s

    resp = Puppy.get url, headers
    resp.body_io.getb_to_end.size.should eq(100 * 1024) # httpbin only generate up to 100KB data
  end

  # it "timeout" do
  #   # curl -X GET "https://httpbin.org/delay/5" -H  "accept: application/json"
  #   #
  #   headers = HTTP::Headers.new
  #   headers["accept"] = "application/json"
  #   url = "https://httpbin.org/delay/5"

  #   resp = Puppy.get url, headers, timeout: 1.seconds
  # end

  it "post json" do
    # curl -X POST "https://httpbin.org/post" -H  "accept: application/json" -H "content-type: application/json" -d "{\"title\": \"foo\", \"body\": \"bar\"}"
    #
    resp = Puppy.post "https://httpbin.org/post", HTTP::Headers{"content-type" => "application/json; charset=UTF-8"}, {"title" => "foo", "body" => "bar"}.to_json
    json = JSON.parse(resp.body_io)
    json.dig("json", "title").as_s.should eq "foo"
    json.dig("json", "body").as_s.should eq "bar"
  end
end
