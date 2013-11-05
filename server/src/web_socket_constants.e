note
	description: "Constants for WebSockets"
	date: "$Date$"
	revision: "$Revision$"

class
	WEB_SOCKET_CONSTANTS

feature -- Constants


	HTTP_1_1: STRING = "HTTP/1.1 101 WebSocket Protocol Handshake"

	Upgrade_ws: STRING = "Upgrade: WebSocket"

	Connection_ws: STRING = "Connection: Upgrade"

	Sec_WebSocket_Origin: STRING = "Sec-WebSocket-Origin: "

	Sec_WebSocket_Protocol: STRING = "Sec-WebSocket-Protocol: "

	Sec_WebSocket_Location: STRING = "Sec-WebSocket-Location: "

	Sec_WebSocket_Version: STRING = "Sec-WebSocket-Version: "

	Sec_WebSocket_Extensions: STRING = "Sec-WebSocket-Extensions: "

	WebSocket_Origin: STRING = "WebSocket-Origin: "

	WebSocket_Protocol: STRING = "WebSocket-Protocol: "

	WebSocket_Location: STRING = "WebSocket-Location: "

	Origin: STRING = "Origin"

	Server: STRING = "EWSS"

	Sec_WebSocket_Key: STRING = "Sec-WebSocket-Key"

	Ws_scheme: STRING = "ws://"

	Wss_scheme: STRING = "wss://"

	Magic_guid: STRING = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

		-- The handshake from the client looks as follows:

		--        GET /chat HTTP/1.1
		--        Host: server.example.com
		--        Upgrade: websocket
		--        Connection: Upgrade
		--        Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
		--        Origin: http://example.com
		--        Sec-WebSocket-Protocol: chat, superchat
		--        Sec-WebSocket-Version: 13

		--   The handshake from the server looks as follows:

		--        HTTP/1.1 101 Switching Protocols
		--        Upgrade: websocket
		--        Connection: Upgrade
		--        Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
		--        Sec-WebSocket-Protocol: chat

feature -- Opcodes Standard actions

		--| Maybe we need an enum STANDARD_ACTIONS_OPCODES?
		--     |Opcode  | Meaning                             | Reference |
		--    -+--------+-------------------------------------+-----------|
		--     | 0      | Continuation Frame                  | RFC 6455  |
		--    -+--------+-------------------------------------+-----------|
		--     | 1      | Text Frame                          | RFC 6455  |
		--    -+--------+-------------------------------------+-----------|
		--     | 2      | Binary Frame                        | RFC 6455  |
		--    -+--------+-------------------------------------+-----------|
		--     | 8      | Connection Close Frame              | RFC 6455  |
		--    -+--------+-------------------------------------+-----------|
		--     | 9      | Ping Frame                          | RFC 6455  |
		--    -+--------+-------------------------------------+-----------|
		--     | 10     | Pong Frame                          | RFC 6455  |
		--    -+--------+-------------------------------------+-----------|

	Continuation_frame: INTEGER = 0

	Text_frame: INTEGER = 1

	Binary_frame: INTEGER = 2

	Connection_close_frame: INTEGER = 8

	Ping_frame: INTEGER = 9

	Pong_frame: INTEGER = 10

feature -- Close code numbers

		-- Maybe an ENUM CLOSE_CODES

		--	   |Status Code | Meaning         | Contact       | Reference |
		--    -+------------+-----------------+---------------+-----------|
		--     | 1000       | Normal Closure  | hybi@ietf.org | RFC 6455  |
		--    -+------------+-----------------+---------------+-----------|
		--     | 1001       | Going Away      | hybi@ietf.org | RFC 6455  |
		--    -+------------+-----------------+---------------+-----------|
		--     | 1002       | Protocol error  | hybi@ietf.org | RFC 6455  |
		--    -+------------+-----------------+---------------+-----------|
		--     | 1003       | Unsupported Data| hybi@ietf.org | RFC 6455  |
		--    -+------------+-----------------+---------------+-----------|
		--     | 1004       | ---Reserved---- | hybi@ietf.org | RFC 6455  |
		--    -+------------+-----------------+---------------+-----------|
		--     | 1005       | No Status Rcvd  | hybi@ietf.org | RFC 6455  |
		--    -+------------+-----------------+---------------+-----------|
		--     | 1006       | Abnormal Closure| hybi@ietf.org | RFC 6455  |
		--    -+------------+-----------------+---------------+-----------|
		--     | 1007       | Invalid frame   | hybi@ietf.org | RFC 6455  |
		--     |            | payload data    |               |           |
		--    -+------------+-----------------+---------------+-----------|
		--     | 1008       | Policy Violation| hybi@ietf.org | RFC 6455  |
		--    -+------------+-----------------+---------------+-----------|
		--     | 1009       | Message Too Big | hybi@ietf.org | RFC 6455  |
		--    -+------------+-----------------+---------------+-----------|
		--     | 1010       | Mandatory Ext.  | hybi@ietf.org | RFC 6455  |
		--    -+------------+-----------------+---------------+-----------|
		--     | 1011       | Internal Server | hybi@ietf.org | RFC 6455  |
		--     |            | Error           |               |           |
		--    -+------------+-----------------+---------------+-----------|
		--     | 1015       | TLS handshake   | hybi@ietf.org | RFC 6455  |
		--    -+------------+-----------------+---------------+-----------|

end
