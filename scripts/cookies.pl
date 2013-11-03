sub new_cookie {
	my $name = shift;
	my $Session_ID = generate_key();
	my $c = CGI::Cookie->new(-name => 'Session ID', -value => $Session_ID);
   $cookies_db{$Session_ID} = $name;
	return $c;
}

# Run when login to give them an existing cookie if password matches
sub give_cookie {
	my ($name, $password) = @_;
	my $validcookie;
	if (authenticate($name,$password) and $user_details{'validated'} eq "1") {
		$validcookie = new_cookie($name);
		$username = $name;
		$valid = 1;
	}
	return $validcookie;
}

# Checks if the Session ID is valid.
sub check_cookie {
	my $valid = 0;
	if (defined $_[0]) {
		my $user = $_[0];
		bless $user, CGI::Cookie;
		if (defined $user) {
			my $Session_ID = $user->value;
		   $username = $cookies_db{$Session_ID};		
		   if (defined $username) {
				$valid = 1;
		   }
		}
	}
   return $valid;
}

# Gets user cookies
sub get_cookie{
	%user_cookie_list = CGI::Cookie->fetch;
	for my $key (keys %user_cookie_list) {
		if ($key eq "Session ID") {
			$received_cookie = $user_cookie_list{"Session ID"};
		}
	}
	return $received_cookie;
}

#Generates a key
sub generate_key {
 my @chars=('a'..'z','A'..'Z','0'..'9');
 my $key;
 foreach (1..16) {
   $key.=$chars[rand @chars];
 }
 return $key;
}

1
