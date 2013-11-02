#
# HTML at top of every screen, if the user is logged in
#
sub page_header_user() {
	my $user = "inactive";
	my $search = "inactive";
	my $help = "inactive";
	my $arg = shift;
   my $cookie = shift;
   bless $cookie, CGI::Cookie if defined $cookie;
	if ($arg eq "User") {
	   $user = "active";
	} elsif ($arg eq "Search") {
	   $search = "active";
	} elsif ($arg eq "Help") {
	   $help = "active";
	}
	my %template_variables = (
		login => $login,
		search => $search,
		help => $help,
	);
   $cookie->bake if defined $cookie;
	my $template = HTML::Template->new(filename => "html/page_User.template", die_on_bad_params => 0);
	$template->param(%template_variables);
   print header;
	print $template->output;

}

#
# HTML at top of every screen, if no user is logged in
#
sub page_header_noUser() {
	my $login = "inactive";
	my $search = "inactive";
	my $help = "inactive";
	my $register = "inactive";
	my $arg = shift;
	if ($arg eq "Login") {
	   $login = "active";

	} elsif ($arg eq "Search") {
	   $search = "active";
	} elsif ($arg eq "Help") {
	   $help = "active";
	} elsif ($arg eq "register_form"){
	   $register = "active";
	}

	my %template_variables = (
		login => $login,
		search => $search,
		help => $help,
		register => $register
	);
	my $template = HTML::Template->new(filename => "html/page_noUser.template", die_on_bad_params => 0);
	$template->param(%template_variables);
   print header;
	print $template->output;
	
}

#
# HTML at bottom of every screen
#
sub page_trailer() {
	my $debugging_info = "";
	if ($debug) {
		$debugging_info = debugging_info();
	}
	return <<eof;
	$debugging_info
</body>
</html>
eof
}
1
