


# simple login form with authentication	
sub login_form {
	open F, "html/login_form.html";
	my @lines = <F>;
	return join "",@lines;
}

# simple register form
sub register_form {
	my $error = $_[0];
	if (defined $error) {
		my %template_variables = (
		error => $error,
		);
		$message = $template_variables{'error'};
		my $template = HTML::Template->new(filename => "html/error.template", die_on_bad_params => 0);
		$template->param(%template_variables);
		print $template->output;
	}
	open F, "html/register_form.html";
	my @lines = <F>;
	return join "",@lines;
}

1
