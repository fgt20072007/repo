return {
	Name = "sendglobalmessage";
	Aliases = {"sg"};
	Description = "Send a global message to all servers.";
	Group = "Admin";
	Args = {
		{
			Type = "string";
			Name = "message";
			Description = "The message to be sent";
		},
	};
}