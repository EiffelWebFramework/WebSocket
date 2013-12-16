note
	description: "ws_client application root class"
	date: "$Date$"
	revision: "$Revision$"

class
	APPLICATION

inherit

	ARGUMENTS

create
	make

feature {NONE} -- Initialization

	make
			-- Run application.
		local
			ws_client: EXAMPLE_WS_CLIENT
			l_env: EXECUTION_ENVIRONMENT
			l_protocols: LIST[STRING]
		do
			create {ARRAYED_LIST[STRING]}l_protocols.make (0)
--			l_protocols.fill (<<"com.kaazing.echo","example.imaginary.protocol">>)
			create l_env
--			create ws_client.make_with_port ("wss://echo.websocket.org",443, Void)
			create ws_client.make_with_port ("wss://127.0.0.1",9090, Void)
			ws_client.launch
			run
		end

	run
			-- Start the server
		local
			l_thread: EXECUTION_ENVIRONMENT
		do
			create l_thread
			from
			until
				False
			loop
				l_thread.sleep (1000000)
			end
		end

end
