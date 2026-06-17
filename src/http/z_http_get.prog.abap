*&---------------------------------------------------------------------*
*& Report Z_GET_HTTP
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_http_get.

DATA: lo_http_client TYPE REF TO if_http_client,
      lv_url         TYPE string VALUE 'https://api.example.com/endpoint',
      lv_response    TYPE string,
      lv_http_code   TYPE i,
      lv_reason      TYPE string.

" Step 1: 创建 HTTP 客户端实例
CALL METHOD cl_http_client=>create_by_url
  EXPORTING
    url                = lv_url
  IMPORTING
    client             = lo_http_client
  EXCEPTIONS
    argument_not_found = 1
    plugin_not_active  = 2
    internal_error     = 3
    OTHERS             = 4.

IF sy-subrc <> 0.
  MESSAGE '创建HTTP客户端失败' TYPE 'E'.
  RETURN.
ENDIF.

" Step 2: 设置请求方法为 GET（默认即为 GET，可省略）
lo_http_client->request->set_method( if_http_request=>co_request_method_get ).

" Step 3: 设置请求头
CALL METHOD lo_http_client->request->set_header_field
  EXPORTING
    name  = 'Content-Type'
    value = 'application/json;charset=UTF-8'.

CALL METHOD lo_http_client->request->set_header_field
  EXPORTING
    name  = 'Authorization'
    value = 'Bearer your_token_here'.

" Step 4: 发送请求
CALL METHOD lo_http_client->send
  EXCEPTIONS
    http_communication_failure = 1
    http_invalid_state         = 2.

IF sy-subrc <> 0.
  MESSAGE '发送HTTP请求失败' TYPE 'E'.
  RETURN.
ENDIF.

" Step 5: 接收响应
CALL METHOD lo_http_client->receive
  EXCEPTIONS
    http_communication_failure = 1
    http_invalid_state         = 2
    http_processing_failed     = 3.

IF sy-subrc <> 0.
  MESSAGE '接收HTTP响应失败' TYPE 'E'.
  RETURN.
ENDIF.

" Step 6: 获取响应状态码和内容
lo_http_client->response->get_status(
  IMPORTING
    code   = lv_http_code
    reason = lv_reason
).

lv_response = lo_http_client->response->get_cdata( ).  " 获取字符串响应
" lv_response_xstr = lo_http_client->response->get_data( ).  " 获取二进制响应

" Step 7: 关闭客户端连接
lo_http_client->close( ).

" Step 8: 处理响应数据
IF lv_http_code = 200.
  MESSAGE |请求成功: { lv_response }| TYPE 'S'.
ELSE.
  MESSAGE |请求失败(HTTP { lv_http_code }): { lv_reason }| TYPE 'E'.
ENDIF.
