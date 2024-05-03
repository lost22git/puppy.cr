require "uri"
require "http/headers"
require "http/request"
require "http/client/response"

require "compress/gzip"
require "compress/zlib"

require "./lib_winhttp"

module Puppy::Fetch
  # :nodoc:
  #
  def self.fetch(req : HTTP::Request, decompress : Bool = true, timeout : Time::Span = 10.seconds, trust_all_certs : Bool = false, proxy_addr : String? = nil) : HTTP::Client::Response
    url = URI.parse req.resource
    scheme = url.scheme
    if !scheme
      raise Error.new "Failed to parse scheme from url: " + url.to_s
    end
    host = url.host
    if !host
      raise Error.new "Failed to parse host from url: " + url.to_s
    end
    port = url.port || URI.default_port(scheme)
    if !port
      raise Error.new "Failed to parse port from url: " + url.to_s
    end
    request_target = url.request_target

    begin
      # open session
      #
      if proxy_addr
        proxy_flag = LibWinHttp::WINHTTP_ACCESS_TYPE_NAMED_PROXY
        w_proxy_addr = proxy_addr.to_utf16
      else
        proxy_flag = LibWinHttp::WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY
        w_proxy_addr = "".to_utf16
      end
      user_agent = (req.headers["user-agent"]? || UA).to_utf16
      hSession = LibWinHttp.WinHttpOpen(
        user_agent,
        proxy_flag,
        w_proxy_addr,
        nil,
        0
      )
      if !hSession
        raise Error.new "WinHttpOpen error: " + LibC.GetLastError.to_s
      end

      # config timeout
      #
      ms = timeout.total_milliseconds
      if LibWinHttp.WinHttpSetTimeouts(hSession, ms, ms, ms, ms) == 0
        raise Error.new "WinHttpSetTimeouts error: " + LibC.GetLastError.to_s
      end

      # connect
      #
      hostname = host.to_utf16
      hConnect = LibWinHttp.WinHttpConnect(
        hSession,
        hostname,
        port,
        0
      )
      if !hConnect
        raise Error.new "WinHttpConnect error: " + LibC.GetLastError.to_s
      end

      # open request
      #
      dbg! req.method.upcase
      dbg! request_target
      verb = req.method.upcase.to_utf16
      object_name = request_target.to_utf16
      open_request_flags = 0
      open_request_flags |= LibWinHttp::WINHTTP_FLAG_SECURE if scheme == "https"
      hRequest = LibWinHttp.WinHttpOpenRequest(
        hConnect,
        verb,
        object_name,
        nil,
        nil,
        nil,
        open_request_flags
      )
      if !hRequest
        raise Error.new "WinHttpOpenRequest error: " + LibC.GetLastError.to_s
      end

      # add request headers
      #
      request_headers_buf = req.headers.serialize.to_utf16
      dbg! req.headers.serialize
      if LibWinHttp.WinHttpAddRequestHeaders(
           hRequest,
           request_headers_buf,
           -1,
           (LibWinHttp::WINHTTP_ADDREQ_FLAG_ADD | LibWinHttp::WINHTTP_ADDREQ_FLAG_REPLACE)
         ) == 0
        raise Error.new "WinHttpAddRequestHeaders error: " + LibC.GetLastError.to_s
      end

      # send request
      #
      request_body_buf = req.body.try &.getb_to_end || Bytes.new(0)
      request_body_buf_size = request_body_buf.size
      dbg! String.new request_body_buf
      dbg! request_body_buf_size
      if LibWinHttp.WinHttpSendRequest(
           hRequest,
           nil,
           0,
           request_body_buf,
           request_body_buf_size,
           request_body_buf_size,
           0
         ) == 0
        error = LibC.GetLastError
        if trust_all_certs && [
             LibWinHttp::ERROR_WINHTTP_SECURE_FAILURE,
             LibWinHttp::ERROR_INTERNET_INVALID_CA,
             LibWinHttp::ERROR_INTERNET_SEC_CERT_DATE_INVALID,
             LibWinHttp::ERROR_INTERNET_SEC_INVALID_CERT,
             LibWinHttp::ERROR_INTERNET_SEC_CERT_CN_INVALID,
             LibWinHttp::ERROR_INTERNET_SEC_CERT_NO_REV,
             LibWinHttp::ERROR_INTERNET_SEC_CERT_REV_FAILED,
             LibWinHttp::ERROR_INTERNET_SEC_CERT_REVOKED,
             LibWinHttp::ERROR_INTERNET_SEC_CERT_ERRORS,
           ].includes?(error)
          # If this is a certificate error but we should allow any HTTPS cert,
          # we need to set some options and retry sending the request.
          # https://stackoverflow.com/questions/19338395/how-do-you-use-winhttp-to-do-ssl-with-a-self-signed-cert
          security_flags : LibWinHttp::DWORD = LibWinHttp::SECURITY_FLAG_IGNORE_UNKNOWN_CA |
            LibWinHttp::SECURITY_FLAG_IGNORE_CERT_WRONG_USAGE |
            LibWinHttp::SECURITY_FLAG_IGNORE_CERT_CN_INVALID |
            LibWinHttp::SECURITY_FLAG_IGNORE_CERT_DATE_INVALID
          if LibWinHttp.WinHttpSetOption(
               hRequest,
               LibWinHttp::WINHTTP_OPTION_SECURITY_FLAGS,
               pointerof(security_flags),
               sizeof(typeof(security_flags))
             ) == 0
            raise Error.new "WinHttpSetOption error: " + LibC.GetLastError.to_s
          end
          if LibWinHttp.WinHttpSendRequest(
               hRequest,
               nil,
               0,
               request_body_buf,
               request_body_buf_size,
               request_body_buf_size,
               0
             ) == 0
            raise Error.new "WinHttpSendRequest error: " + LibC.GetLastError.to_s
          end
        else
          raise Error.new "WinHttpSendRequest error: " + LibC.GetLastError.to_s
        end
      end

      # receive response
      #
      if LibWinHttp.WinHttpReceiveResponse(hRequest, nil) == 0
        raise Error.new "WinHttpReceiveResponse error: " + LibC.GetLastError.to_s
      end

      # read status code
      #
      status_code = uninitialized Int32
      status_code_buf_size = sizeof(LibWinHttp::DWORD).to_u32
      if LibWinHttp.WinHttpQueryHeaders(
           hRequest,
           LibWinHttp::WINHTTP_QUERY_STATUS_CODE | LibWinHttp::WINHTTP_QUERY_FLAG_NUMBER,
           nil,
           pointerof(status_code),
           pointerof(status_code_buf_size),
           nil
         ) == 0
        raise Error.new "Read status code: WinHttpQueryHeaders error: " + LibC.GetLastError.to_s
      end
      dbg! status_code

      # read response headers
      #
      response_headers_buf = uninitialized Slice(LibWinHttp::WCHAR)
      response_headers_buf_size = uninitialized LibWinHttp::DWORD
      LibWinHttp.WinHttpQueryHeaders(
        hRequest,
        LibWinHttp::WINHTTP_QUERY_RAW_HEADERS_CRLF,
        nil,
        nil,
        pointerof(response_headers_buf_size),
        nil
      )
      error_code = LibC.GetLastError
      if error_code == LibWinHttp::ERROR_INSUFFICIENT_BUFFER
        response_headers_buf = Slice(LibWinHttp::WCHAR).new(response_headers_buf_size // 2)
      else
        raise Error.new "Read response headers bytesize: WinHttpQueryHeaders error: " + error_code.to_s
      end
      dbg! response_headers_buf_size
      if LibWinHttp.WinHttpQueryHeaders(
           hRequest,
           LibWinHttp::WINHTTP_QUERY_RAW_HEADERS_CRLF,
           nil,
           response_headers_buf,
           pointerof(response_headers_buf_size),
           nil
         ) == 0
        raise Error.new "Read response headers: WinHttpQueryHeaders error: " + error_code.to_s
      end

      dbg! String.from_utf16(response_headers_buf)

      # convert response headers to HTTP::Headers
      #
      response_headers = parse_response_headers response_headers_buf
      dbg! response_headers
      if response_headers.size == 0
        raise Error.new "Failed to parsing response headers"
      end

      # read reponse body
      #
      response_body_io = uninitialized IO
      response_body_buf = Bytes.new RESPONSE_BODY_INIT_SIZE
      total_read_size = 0
      while true
        read_size = uninitialized LibWinHttp::DWORD
        to_read_size = response_body_buf.size - total_read_size
        if LibWinHttp.WinHttpReadData(
             hRequest,
             response_body_buf.to_unsafe + total_read_size,
             to_read_size,
             pointerof(read_size)
           ) == 0
          raise Error.new "WinHttpReadData error: " + LibC.GetLastError.to_s
        end
        break if read_size == 0 # complete read
        total_read_size += read_size
        if total_read_size >= RESPONSE_BODY_MAX_SIZE
          raise Error.new "Failed to read response body, reach RESPONSE_BODY_MAX_SIZE: " + RESPONSE_BODY_MAX_SIZE.to_s
        elsif total_read_size == response_body_buf.size # expand response body buffer
          new_size = Math.min(total_read_size * 2, RESPONSE_BODY_MAX_SIZE)
          response_body_buf = Bytes.new response_body_buf.to_unsafe.realloc(new_size), new_size
        end
      end
      readable_response_body_buf = Bytes.new response_body_buf.to_unsafe, total_read_size, read_only: true
      response_body_io = IO::Memory.new readable_response_body_buf, writeable: false

      # decompress response body
      #
      if decompress
        content_encoding = response_headers["content-encoding"]?
        dbg! content_encoding
        response_body_io = decompress(response_body_io, format: content_encoding) if content_encoding
      end

      # return HTTP::Client::Response
      #
      HTTP::Client::Response.new status_code: status_code, headers: response_headers, body_io: response_body_io
    ensure
      LibWinHttp.WinHttpCloseHandle hRequest if hRequest
      LibWinHttp.WinHttpCloseHandle hConnect if hConnect
      LibWinHttp.WinHttpCloseHandle hSession if hSession
    end
  end

  private def self.parse_response_headers(buf : Slice(UInt16)) : HTTP::Headers
    result = HTTP::Headers.new
    String.from_utf16(buf)
      .split(CRLF, remove_empty: true)
      .each_with_index do |header_line, i|
        next unless i > 0 # skip first line that is HTTP/1.1 200 OK
        kv = header_line.split(":", 2)
        result.add kv[0].strip, kv[1].strip if kv.size == 2
      end
    result
  end

  private def self.decompress(io : IO, format : String) : IO
    case format.downcase
    when "gzip"
      Compress::Gzip::Reader.new io, sync_close: true
    when "deflate"
      Compress::Zlib::Reader.new io, sync_close: true
    else
      io
    end
  end
end
