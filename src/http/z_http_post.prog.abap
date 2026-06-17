*&---------------------------------------------------------------------*
*& Report Z_HTTP_POST
*&---------------------------------------------------------------------*
*&  请求https可能报ssl相关错误，需要在 Strust 中维护目标证书
*&---------------------------------------------------------------------*
REPORT z_http_post.

DATA: lo_http_client TYPE REF TO if_http_client,
      lv_url         TYPE string VALUE 'https://api.example.com/create',
      lv_json_body   TYPE string,
      lv_response    TYPE string,
      lv_http_code   TYPE i,
      lv_reason      TYPE string,
      lv_token       TYPE string VALUE 'your_access_token'.

" ==================== Step 1: 创建 HTTP 客户端实例 ====================
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
  MESSAGE |创建HTTP客户端失败(SUBRC:{ sy-subrc })| TYPE 'E'.
  RETURN.
ENDIF.

" ==================== Step 2: 设置请求方法为 POST ====================
lo_http_client->request->set_method( if_http_request=>co_request_method_post ).

" ==================== Step 3: 设置请求头 ====================
CALL METHOD lo_http_client->request->set_header_field
  EXPORTING
    name  = 'Content-Type'
    value = 'application/json;charset=UTF-8'.

CALL METHOD lo_http_client->request->set_header_field
  EXPORTING
    name  = 'Authorization'
    value = |Bearer { lv_token }|.

CALL METHOD lo_http_client->request->set_header_field
  EXPORTING
    name  = 'Accept'
    value = 'application/json'.

" ==================== Step 4: 准备请求体数据(JSON) ====================
DATA: ls_request TYPE string.
ls_request = `{"name":"张三","email":"zhangsan@example.com","age":30}`.

lo_http_client->request->set_cdata(
  EXPORTING
    data   = ls_request
    offset = 0
    length = strlen( ls_request )
).

" ==================== Step 5: 发送请求 ====================
CALL METHOD lo_http_client->send
  EXCEPTIONS
    http_communication_failure = 1
    http_invalid_state         = 2.

IF sy-subrc <> 0.
  DATA: lv_error_msg TYPE string.
  lo_http_client->get_last_error( IMPORTING message = lv_error_msg ).
  MESSAGE |发送请求失败: { lv_error_msg }| TYPE 'E'.
  RETURN.
ENDIF.

" ==================== Step 6: 接收响应 ====================
CALL METHOD lo_http_client->receive
  EXCEPTIONS
    http_communication_failure = 1
    http_invalid_state         = 2
    http_processing_failed     = 3.

IF sy-subrc <> 0.
  lo_http_client->get_last_error( IMPORTING message = lv_error_msg ).
  MESSAGE |接收响应失败: { lv_error_msg }| TYPE 'E'.
  RETURN.
ENDIF.

" ==================== Step 7: 获取响应信息 ====================
lo_http_client->response->get_status(
  IMPORTING
    code   = lv_http_code
    reason = lv_reason
).

lv_response = lo_http_client->response->get_cdata( ).

" ==================== Step 8: 关闭客户端 ====================
CALL METHOD lo_http_client->close( ).

" ==================== Step 9: 处理响应 ====================
IF lv_http_code = 200.
  MESSAGE |POST请求成功!| TYPE 'S'.
  WRITE: / '响应内容:', lv_response.
ELSE.
  MESSAGE |POST请求失败(HTTP { lv_http_code }): { lv_reason }| TYPE 'E'.
  WRITE: / '错误响应:', lv_response.
ENDIF.
