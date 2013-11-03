#!/usr/bin/perl -w


use CGI qw/:all/;
use CGI;
use CGI::Cookie;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use HTML::Template;
use Storable;

require 'scripts/forms.pl';
require 'scripts/pages.pl';
require 'scripts/cookies.pl';
require 'scripts/backend.pl';
require 'scripts/page_headers.pl';
require 'scripts/search.pl';
require 'scripts/read_books.pl';
require 'scripts/basket.pl';
require 'scripts/checkout.pl';

warningsToBrowser(1);
$debug = 0;
$| = 1;
cgi_main();
exit 0;

# Reads page and search_results params and serves appropriate webpage

sub cgi_main {
   # Set some variables
   set_global_variables();

   # Setup Cookies
   my $cookies_path = 'data/cookies';
	my $keys_path = 'data/keys';
	my $reset_path = 'data/reset';
	my $status1 = eval '%{retrieve($cookies_path)}';
	my $status2 = eval '%{retrieve($keys_path)}';
	my $status3 = eval '%{retrieve($reset_path)}';
	my $received_cookie;
	%cookies_db = %{retrieve($cookies_path)} if defined $status1;
	%validate_keys = %{retrieve($keys_path)} if defined $status2;
	%reset_keys = %{retrieve($reset_path)} if defined $status3;

	$valid = 0;

   # Get Page
   my $page = param('page');

	$received_cookie = get_cookie();

   # Check if their cookie exists in system and they are logged in, or give
   # them a cookie if they just logged in
	if ($page eq "postLogin") {
	   $send_cookie = give_cookie(param('login'), param('password'));
	} else {
	   $valid = check_cookie($received_cookie) if defined $received_cookie;
	}
	bless $send_cookie, CGI::Cookie if defined $send_cookie;
   # Determines which header to give, depending on if they are logged in
   if (defined $send_cookie) {			
		if ($page eq "postLogin") {				
	   	page_header_user($page, $send_cookie);
		}
   } elsif ($valid and $page ne 'logOut') {	
		page_header_user($page);
	} else {
		page_header_noUser($page);
   }
	# Read in books
   read_books($books_file);
	
	serve_page($page, $send_cookie, $received_cookie);
	print page_trailer();
	
	store \%cookies_db, $cookies_path;
	store \%validate_keys, $keys_path;
	store \%reset_keys, $reset_path;
}



#
# Print out information for debugging purposes
#
sub debugging_info() {
	my $params = "";
  
	foreach $p (param()) {
		$params .= "param($p)=".param($p)."\n"
	}
   
	print "<hr>\n<h4>Debugging information - parameter values supplied to $0</h4>\n<pre>"; 
	print "Session ID: ", $user_cookie_list{'Session ID'}->value if exists $user_cookie_list{'Session ID'};
	print $message if defined $message;
	print "</pre>";
}



