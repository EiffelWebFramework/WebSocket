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
		do
			create l_env
			create ws_client.make_with_port ("ws://127.0.0.1", 9090)
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
