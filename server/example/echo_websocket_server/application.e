note
	description: "Websocket server."
	date: "$Date$"
	revision: "$Revision$"

class
	APPLICATION

inherit
	WEB_SOCKET_SERVICE [APPLICATION_CONNECTION_HANDLER]

create
	make_and_launch

feature {NONE} -- Initialization

	make_with_port (a_port: INTEGER)
			-- Create Current application using port `a_port'.
		do
			make
			server_configuration.set_http_server_port (a_port)
		end

	setup (a_cfg: HTTPD_CONFIGURATION)
		do
			if a_cfg.has_ssl_support then
				a_cfg.mark_secure
				a_cfg.set_ca_crt ("C:\OpenSSL-Win64\bin\ca.crt") -- Change to use your own crt file.
				a_cfg.set_ca_key ("C:\OpenSSL-Win64\bin\ca.key") -- Change to use your own key file.
				a_cfg.set_ssl_protocol_to_ssl_2_or_3
			end

			a_cfg.set_is_verbose (True) -- For debug purpose.

			a_cfg.http_server_port := default_port_number
			a_cfg.set_max_concurrent_connections (50)
		end

feature -- Access

	default_port_number: INTEGER = 9090

note
	copyright: "2011-2016, Javier Velilla, Jocelyn Fiat and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end

