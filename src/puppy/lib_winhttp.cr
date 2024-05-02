# LibWinHttp
#
# [WinHttp Doc](https://learn.microsoft.com/en-us/windows/win32/winhttp/using-the-winhttp-c-c---api)
#
@[Link("winhttp")]
lib Puppy::LibWinHttp
  # ------ constants -----------------------

  WINHTTP_ACCESS_TYPE_NO_PROXY        = 1_u32
  WINHTTP_ACCESS_TYPE_NAMED_PROXY     = 3_u32
  WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY = 4_u32

  WINHTTP_FLAG_SECURE            = 0x00800000_u32
  WINHTTP_ADDREQ_FLAG_ADD        = 0x20000000_u32
  WINHTTP_ADDREQ_FLAG_REPLACE    = 0x80000000_u32
  WINHTTP_QUERY_FLAG_NUMBER      = 0x20000000_u32
  WINHTTP_QUERY_STATUS_CODE      =         19_u32
  WINHTTP_QUERY_RAW_HEADERS_CRLF =         22_u32
  WINHTTP_OPTION_SECURITY_FLAGS  =         31_u32
  WINHTTP_OPTION_URL             =         34_u32

  ERROR_INSUFFICIENT_BUFFER            =   122_u32
  ERROR_WINHTTP_TIMEOUT                = 12002_u32
  ERROR_WINHTTP_SECURE_FAILURE         = 12175_u32
  ERROR_INTERNET_INVALID_CA            = 12045_u32
  ERROR_INTERNET_SEC_CERT_DATE_INVALID = 12037_u32
  ERROR_INTERNET_SEC_INVALID_CERT      = 12169_u32
  ERROR_INTERNET_SEC_CERT_ERRORS       = 12055_u32
  ERROR_INTERNET_SEC_CERT_NO_REV       = 12056_u32
  ERROR_INTERNET_SEC_CERT_CN_INVALID   = 12038_u32
  ERROR_INTERNET_SEC_CERT_REV_FAILED   = 12057_u32
  ERROR_INTERNET_SEC_CERT_REVOKED      = 12170_u32

  SECURITY_FLAG_IGNORE_UNKNOWN_CA        = 0x00000100_u32
  SECURITY_FLAG_IGNORE_CERT_WRONG_USAGE  = 0x00000200_u32
  SECURITY_FLAG_IGNORE_CERT_CN_INVALID   = 0x00001000_u32
  SECURITY_FLAG_IGNORE_CERT_DATE_INVALID = 0x00002000_u32

  WINHTTP_DECOMPRESSION_FLAG_GZIP    = 0x00000001_u32
  WINHTTP_DECOMPRESSION_FLAG_DEFLATE = 0x00000002_u32
  WINHTTP_DECOMPRESSION_FLAG_ALL     = (WINHTTP_DECOMPRESSION_FLAG_GZIP | WINHTTP_DECOMPRESSION_FLAG_DEFLATE)

  # ------ type alias ----------------------

  {% if flag?(:bits64) %}
    alias ULONG_PTR = UInt64
  {% else %}
    alias ULONG_PTR = UInt32
  {% end %}

  alias BOOL = Int32
  alias WORD = UInt16
  alias DWORD = UInt32
  alias DWORD_PTR = ULONG_PTR
  alias LPDWORD = DWORD*
  alias WCHAR = UInt16
  alias LPCWSTR = WCHAR*
  alias INTERNET_PORT = WORD
  alias HINTERNET = Void*
  alias LPVOID = Void*

  # ------ funtions ------------------------

  # The `WinHttpOpen` function initializes, for an application, the use of WinHTTP functions and returns a WinHTTP-session handle.
  #
  # [doc](https://learn.microsoft.com/en-us/windows/win32/api/winhttp/nf-winhttp-winhttpopen)
  #
  fun WinHttpOpen(
    lpszAgent : LPCWSTR,
    dwAccessType : DWORD,
    lpszProxy : LPCWSTR,
    lpszProxyBypass : LPCWSTR,
    dwFlags : DWORD
  ) : HINTERNET

  # The `WinHttpSetTimeouts` function sets time-outs involved with HTTP transactions.
  #
  # [doc](https://learn.microsoft.com/en-us/windows/win32/api/winhttp/nf-winhttp-winhttpsettimeouts)
  #
  fun WinHttpSetTimeouts(
    hSession : HINTERNET,
    nResolveTimeout : Int32,
    nConnectTimeout : Int32,
    nSendTimeout : Int32,
    nReceiveTimeout : Int32
  ) : BOOL

  # The `WinHttpConnect` function specifies the initial target server of an HTTP request and returns an `HINTERNET` connection handle to an HTTP session for that initial target.
  #
  # [doc](https://learn.microsoft.com/en-us/windows/win32/api/winhttp/nf-winhttp-winhttpconnect)
  #
  fun WinHttpConnect(
    hSession : HINTERNET,
    lpszServerName : LPCWSTR,
    nServerPort : INTERNET_PORT,
    dwFlags : DWORD
  ) : HINTERNET

  # The `WinHttpOpenRequest` function creates an HTTP request handle.
  #
  # [doc](https://learn.microsoft.com/en-us/windows/win32/api/winhttp/nf-winhttp-winhttpopenrequest)
  #
  fun WinHttpOpenRequest(
    hConnect : HINTERNET,
    lpszVerb : LPCWSTR,
    lpszObjectName : LPCWSTR,
    lpszVersion : LPCWSTR,
    lpszReferrer : LPCWSTR,
    lplpszAcceptTypes : LPCWSTR*,
    dwFlags : DWORD
  ) : HINTERNET

  # The `WinHttpSetOption` function sets an Internet option.
  #
  # [doc](https://learn.microsoft.com/en-us/windows/win32/api/winhttp/nf-winhttp-winhttpsetoption)
  #
  fun WinHttpSetOption(
    hInternet : HINTERNET,
    dwOption : DWORD,
    lpBuffer : LPVOID,
    dwBufferLength : DWORD
  ) : BOOL

  # The `WinHttpAddRequestHeaders` function adds one or more HTTP request headers to the HTTP request handle.
  #
  # [doc](https://learn.microsoft.com/en-us/windows/win32/api/winhttp/nf-winhttp-winhttpaddrequestheaders)
  #
  fun WinHttpAddRequestHeaders(
    hRequest : HINTERNET,
    lpszHeaders : LPCWSTR,
    dwHeadersLength : DWORD,
    dwModifiers : DWORD
  ) : BOOL

  # The `WinHttpSendRequest` function sends the specified request to the HTTP server.
  #
  # [doc](https://learn.microsoft.com/en-us/windows/win32/api/winhttp/nf-winhttp-winhttpsendrequest)
  #
  fun WinHttpSendRequest(
    hRequest : HINTERNET,
    lpszHeaders : LPCWSTR,
    dwHeadersLength : DWORD,
    lpOptional : LPVOID,
    dwOptionalLength : DWORD,
    dwTotalLength : DWORD,
    dwContext : DWORD_PTR
  ) : BOOL

  # The `WinHttpReceiveResponse` function waits to receive the response to an HTTP request initiated by `WinHttpSendRequest`.
  # When `WinHttpReceiveResponse` completes successfully, the status code and response headers have been received and are available for the application to inspect using `WinHttpQueryHeaders`.
  # An application must call `WinHttpReceiveResponse` before it can use `WinHttpQueryDataAvailable` and `WinHttpReadData` to access the response entity body (if any).
  #
  # [doc](https://learn.microsoft.com/en-us/windows/win32/api/winhttp/nf-winhttp-winhttpreceiveresponse)
  #
  fun WinHttpReceiveResponse(
    hRequest : HINTERNET,
    lpReserved : LPVOID
  ) : BOOL

  # The `WinHttpQueryHeaders` function retrieves header information associated with an HTTP request.
  #
  # [doc](https://learn.microsoft.com/en-us/windows/win32/api/winhttp/nf-winhttp-winhttpqueryheaders)
  #
  fun WinHttpQueryHeaders(
    hRequest : HINTERNET,
    dwInfoLevel : DWORD,
    pwszName : LPCWSTR,
    lpBuffer : LPVOID,
    lpdwBufferLength : LPDWORD,
    lpdwIndex : LPDWORD
  ) : BOOL

  # The `WinHttpQueryOption` function queries an Internet option on the specified handle.
  #
  # [doc](https://learn.microsoft.com/en-us/windows/win32/api/winhttp/nf-winhttp-winhttpqueryoption)
  #
  fun WinHttpQueryOption(
    hRequest : HINTERNET,
    dwOption : DWORD,
    lpBuffer : LPVOID,
    lpdwBufferLength : LPDWORD
  ) : BOOL

  # The `WinHttpReadData` function reads data from a handle opened by the WinHttpOpenRequest function.
  #
  # [doc](https://learn.microsoft.com/en-us/windows/win32/api/winhttp/nf-winhttp-winhttpreaddata)
  #
  fun WinHttpReadData(
    hFile : HINTERNET,
    lpBuffer : LPVOID,
    dwNumberOfBytesToRead : DWORD,
    lpdwNumberOfBytesRead : LPDWORD
  ) : BOOL

  # The `WinHttpCloseHandle` function closes a single `HINTERNET` handle (see `HINTERNET` Handles in WinHTTP).
  #
  # [doc](https://learn.microsoft.com/en-us/windows/win32/api/winhttp/nf-winhttp-winhttpclosehandle)
  #
  fun WinHttpCloseHandle(hInternet : HINTERNET) : BOOL
end
