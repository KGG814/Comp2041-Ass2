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
		  'postcode='	  
		  );
}

sub new_account {
	my (@values) = @_;
	my $login = shift @values;
	if (!open(USER, ">$users_dir/$login")) {
		print "Can not create user file $users_dir/$login: $!";
		return "";
	}
	my ($value, $count);
	while (@values) {
		$value = shift @values;
		$label = $new_account_rows[$count];
		$count++;
		exit 1 if !$value;
		chomp $value;
		print USER "$label$value\n";		
	}
	close(USER);
	my %template_variables = (
		login => $login
	);
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
	foreach $field (qw(name email password address city state postcode)) {
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
	if (defined param('searchTerms')) {
		search_results(param('searchTerms'));
	} elsif ($page eq "Home") {
		print home_page();
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
		
	} elsif ($page eq "logOut") {
     	delete $cookies_db{$received_cookie->value};
		print home_page(); 	
	} elsif ($page eq "Book") { 
		$isbn = param('isbn');
		my %template_variables = %{$book_details{$isbn}};
		my $template = HTML::Template->new(filename => "html/book_page.template", die_on_bad_params => 0);
		if ($valid) {
			open F, "html/basket.html";
			my @lines = <F>;
			$template_variables{'basket'} = join "",@lines;
		} else {
			$template_variables{'basket'} = "Please login to checkout";
		}
		$template->param(%template_variables);
		print $template->output;
	}
}
1
