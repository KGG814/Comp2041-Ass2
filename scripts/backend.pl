sub set_global_variables {
	$base_dir = ".";
	$books_file = "$base_dir/data/books.json";
	$orders_dir = "$base_dir/orders";
	$baskets_dir = "$base_dir/baskets";
	$users_dir = "$base_dir/users";
	$last_error = "";
	%user_details = ();
	%book_details = ();
	%attribute_names = ();
	@new_account_rows = (
		  'name=',
		  'email=',
		  'password=',	  
		  'address=',
		  'city=',
		  'state=',
		  'postcode=',
		  'validated='	  
		  );
}

sub new_account {
	my (@values) = @_;
	my $login = shift @values;
	my $email = $values[1];
	if (!open(USER, ">$users_dir/$login")) {
		print "Can not create user file $users_dir/$login: $!";
		return "";
	}
	my $value;
	my $count = 0;
	while (@values) {
		$value = shift @values;
		$label = $new_account_rows[$count];

		$count++;
		chomp $value;
		print USER "$label$value\n";		
	}
	close(USER);
	my %template_variables = (
		login => $login,
		email => $email
	);

	$validate_key = generate_key();
	$validate_keys{$validate_key} = $login;
	# Send email
	system("echo \"http://cgi.cse.unsw.edu.au/~kgga769/ass2/Comp2041-Ass2/mekong.cgi?key=$validate_key\" | mail -s \"mekong\" $email");
 	$template = HTML::Template->new(filename => "html/post_register.template", die_on_bad_params => 0);
	$template->param(%template_variables);
	print $template->output;
}

# return true if specified login & password are correct
# user's details are stored in hash user_details

sub authenticate {
	my ($login, $password) = @_;
	our (%user_details, $last_error);
	return 0 if !legal_login($login);
	if (!open(USER, "$users_dir/$login")) {
		$last_error = "User '$login' does not exist.";
		return 0;
	}
	my %details =();
	while (<USER>) {
		next if !/^([^=]+)=(.*)/;
		$details{$1} = $2;
	}
	close(USER);
	foreach $field (qw(name email password address city state postcode validated)) {
		if (!defined $details{$field}) {
 	 	 	$last_error = "Incomplete user file: field $field missing";
			return 0;
		}
	}
	if ($details{"password"} ne $password) {
  	 	$last_error = "Incorrect password.";
		return 0;
	 }
	 %user_details = %details;
  	 return 1;
}

# return true if specified string can be used as a login

sub legal_login {
	my ($login) = @_;
	our ($last_error);

	if ($login !~ /^[a-zA-Z][a-zA-Z0-9]*$/) {
		$last_error = "Invalid login '$login': logins must start with a letter and contain only letters and digits.";
		return 0;
	}
	if (length $login < 3 || length $login > 8) {
		$last_error = "Invalid login: logins must be 3-8 characters long.";
		return 0;
	}
	return 1;
}

sub serve_page {
	($page, $send_cookie, $received_cookie) = @_;
	$page  = "" if (! defined $page);
	if (defined param('searchTerms')) {
		search_results(param('searchTerms'));
	} elsif ($page eq "Login") {
		print login_form();
	} elsif ($page eq "postLogin") {	
		if (! defined $send_cookie) {
			print authenticate_error();
		} else {
			print welcome(param('login'));
		}
	} elsif ($page eq "register_form") {
		print register_form();
	} elsif ($page eq "post_register") {
		post_register();
		
	} elsif ($page eq "logOut" and $valid) {
     	delete $cookies_db{$received_cookie->value};
		print home_page(); 	
	} elsif ($page eq "Book") { 
		books();
	} elsif ($page eq "basket" and $valid) { 
		basket_page();
	} elsif ($page eq "remove" and $valid) { 
		delete_basket(param('isbn'));
		basket_page();
	} elsif (defined param('book_order') and $valid) {
		add_basket(param('book_order'),param('quantity'));
		basket_page();
	} elsif ($page eq "checkout" and $valid) {
		finalize_order();
		basket_page();
	} elsif (defined param('key')){
		if (validate()) {
			$message = "11111";
			print validated();
		} else {
			print home_page();
		}
	} elsif ($page eq "recovery") {
		print recovery_page();
	} elsif ($page eq "resetEmail") {
		resetEmail();
	} elsif (defined param('reset')) {
		resetPass();
	} else {
		print home_page();
	}
}

sub validate {
	my $key = param('key');
	if (defined param('key') and defined $validate_keys{$key}) {
		my $login = $validate_keys{$key};
		open USER, "$users_dir/$login" or die;
		my %details =();
		while (<USER>) {
			next if !/^([^=]+)=(.*)/;
			$details{$1} = $2;
		}
		close(USER);
		$details{'validated'} = "1";
		open USER, ">$users_dir/$login" or die;
		foreach $key (keys %details) {
			print USER "$key=$details{$key}\n"
		}
		delete $validate_keys{$key};
		return 1;
	} else {
		return 0;
	}
}

sub resetPass {
	my $key = param('reset');
	$message = (keys %reset_keys)[0];
	if (defined param('reset') and defined $reset_keys{$key}) {
		my $login = $reset_keys{$key};
		open USER, "$users_dir/$login" or die;
		my %details =();
		while (<USER>) {
			next if !/^([^=]+)=(.*)/;
			$details{$1} = $2;
		}
		close(USER);
		my $email = $details{'email'};
		my $password = generate_key();
		$details{'password'} = $password;
		open USER, ">$users_dir/$login" or die;
		foreach $key (keys %details) {
			print USER "$key=$details{$key}\n"
		}
		system("echo \"New password: $password\" | mail -s \"mekong\" $email");
		open F, "html/password_reset.html";
		my @lines = <F>;
		print (join "",@lines); 
		close F;
	} else {
		print home_page();
	}
	
}

sub resetEmail {
	my $login = param('login');
	if (!open(USER, "$users_dir/$login")) {
		open F, "html/user_not_found.html";
		my @lines = <F>;
		print (join "",@lines); 
		close F;
	} else {
		my %details;
		while (<USER>) {
			next if !/^([^=]+)=(.*)/;
			$details{$1} = $2;
		}
		my $email = $details{'email'};
		$reset_key = generate_key();
		$reset_keys{$reset_key} = $login;
		# Send email
		system("echo \"http://cgi.cse.unsw.edu.au/~kgga769/ass2/Comp2041-Ass2/mekong.cgi?reset=$reset_key\" | mail -s \"mekong\" $email");
		open F, "html/email_reset.html";
		my @lines = <F>;
		print (join "",@lines); 
		close F;
	}
}

1
