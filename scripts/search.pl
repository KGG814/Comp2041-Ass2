# return descriptions of specified books
sub get_book_descriptions {
	my @isbns = @_;
	my %descriptions = ();
	our %book_details;
	foreach $isbn (@isbns) {
		die "Internal error: unknown isbn $isbn in print_books\n" if !$book_details{$isbn}; # shouldn't happen
		my $title = $book_details{$isbn}{'title'} || "";
		my $authors = $book_details{$isbn}{'authors'} || "";
		$authors =~ s/\n([^\n]*)$/ & $1/g;
		$authors =~ s/\n/, /g;
		$descriptions{$isbn}{'title'} = $title;
		$descriptions{$isbn}{'authors'} = $authors;
		$descriptions{$isbn}{'price'} = $book_details{$isbn}{'price'};
	}
	return %descriptions;
}

# ascii display of search results
sub search_results {
	my ($search_terms) = @_;
	my @matching_isbns = search_books($search_terms);
	my %descriptions = get_book_descriptions(@matching_isbns);
	my %head_variables = (search_terms => $search_terms);
 	$head = HTML::Template->new(filename => "html/search_results_head.template", die_on_bad_params => 0);
	$head->param(%head_variables);
	print $head->output;
	foreach my $isbn (sort keys %descriptions) {
		my %table_variables = (isbn => $isbn, image =>$book_details{$isbn}{'smallimageurl'});
		foreach my $key (sort keys %{$descriptions{$isbn}}) {
			$table_variables{$key} = $descriptions{$isbn}{$key};
		}
		my $table = HTML::Template->new(filename => "html/search_results_table.template", die_on_bad_params => 0);
		$table->param(%table_variables);
		print $table->output;
	}
	open F, "html/search_results_tail.html";
	my @lines = <F>;
	print join "",@lines;
}
1
