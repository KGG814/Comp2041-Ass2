# Home	
sub home_page {
	open F, "html/home_page.html";
	my @lines = <F>;
	return join "",@lines;
}

sub authenticate_error {
	open F, "html/authenticate_error.html";
	my @lines = <F>;
	return join "",@lines;
}

sub post_register {
	my $username = param('username');
		my $error;
		if (-r "$users_dir/$username") {
			$error = "User already Exists";
			print register_form($error);
		} else {
			new_account(param('username'),param('name'),param('email'),param('password'),
			param('address'),param('city'),param('state'),param('post_code'));
		}
}

sub welcome {
	my %template_variables = (
		login => param('login'),
	);
	my $template = HTML::Template->new(filename => "html/welcome.template", die_on_bad_params => 0);
	$template->param(%template_variables);
	print $template->output;
}

sub books {
	my $isbn = param('isbn');
	my %template_variables = %{$book_details{$isbn}};
	my $template = HTML::Template->new(filename => "html/book_page.template", die_on_bad_params => 0);
	if ($valid) {
		my %basket_variables = (isbn => $isbn);
		my $basket = HTML::Template->new(filename => "html/basket.template", die_on_bad_params => 0);
		$basket->param(%basket_variables);
		$template_variables{'basket'} = $basket->output;
	} else {
		$template_variables{'basket'} = "Please login to checkout";
	}
	$template->param(%template_variables);
	print $template->output;
}



1

