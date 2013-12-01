note
	description : "test application root class"
	date        : "$Date$"
	revision    : "$Revision$"

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
			ws_client: TEST_AUTOBAHN_CLIENT
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			create ws_client.make_with_host_port_path ("ws://127.0.0.1", 9001, "/runCase?case=1&agent=eiffel/websocket")
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
