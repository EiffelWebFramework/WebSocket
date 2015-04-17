note
	description : "nino application root class"
	date        : "$Date$"
	revision    : "$Revision$"

class
	APPLICATION

inherit
	ARGUMENTS

	SHARED_APPLICATION_CONFIGURATION

create
	make

feature {NONE} -- Initialization

	make_with_port (a_port: INTEGER)
			-- Run application.
		local
			app_cfg: APPLICATION_CONFIGURATION
			cfg: HTTP_SERVER_CONFIGURATION
		do
			create app_cfg.make
			app_cfg.set_document_root (default_document_root)
			set_app_configuration (app_cfg)

			create cfg.make
			setup (cfg, a_port)

			create server.make (cfg, create {separate APPLICATION_FACTORY})
		end

	make
		do
			make_with_port (default_port_number)
			launch
		end

	launch
		do
			server.launch
		end

	setup (a_cfg: HTTP_SERVER_CONFIGURATION; a_port: INTEGER)
		do
			if a_cfg.has_ssl_support then
				a_cfg.mark_secure
				a_cfg.set_ca_crt ("C:\temp\OpenSSL\server.crt") -- Change to use your own crt file.
				a_cfg.set_ca_key ("C:\temp\OpenSSL\server.key") -- Change to use your own key file.
				a_cfg.set_ssl_protocol_to_ssl_2_or_3
			end

			a_cfg.http_server_port := a_port
			a_cfg.set_max_concurrent_connections (50)
			debug ("nino")
				a_cfg.set_is_verbose (True)
			end
		end

feature -- Access

	default_port_number: INTEGER = 9090

	server: HTTP_SERVER

	default_document_root: STRING = "webroot"

note
	copyright: "2011-2015, Javier Velilla, Jocelyn Fiat and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end

