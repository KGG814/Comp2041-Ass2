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
		my $add_to_basket;
		foreach my $key (sort keys %{$descriptions{$isbn}}) {
			$table_variables{$key} = $descriptions{$isbn}{$key};
		}
		if ($valid) {
			$add_to_basket = "<form name=\"addToBasket\"> \n
				<input type=\"hidden\" name=\"quantity\" value=\"1\">\n
				<button class=\"btn btn-small btn-primary\" name=\"book_order\" value=$isbn>Add</button>\n
				</form>\n"
		}
		$table_variables{'add_to_basket'} = $add_to_basket;
		my $table = HTML::Template->new(filename => "html/search_results_table.template", die_on_bad_params => 0);
		$table->param(%table_variables);
		print $table->output;
	}
	open F, "html/search_results_tail.html";
	my @lines = <F>;
	print join "",@lines;
}

# return books matching search string

sub search_books {
	my ($search_string) = @_;
	$search_string =~ s/\s*$//;
	$search_string =~ s/^\s*//;
	return search_books1(split /\s+/, $search_string);
}

# return books matching search terms

sub search_books1 {
	my (@search_terms) = @_;
	our %book_details;
	my @unknown_fields = ();
	foreach $search_term (@search_terms) {
		push @unknown_fields, "'$1'" if $search_term =~ /([^:]+):/ && !$attribute_names{$1};
	}
	printf STDERR "$0: warning unknown field%s: @unknown_fields\n", (@unknown_fields > 1 ? 's' : '') if @unknown_fields;
	my @matches = ();
	BOOK: foreach $isbn (sort keys %book_details) {
		my $n_matches = 0;
		if (!$book_details{$isbn}{'=default_search='}) {
			$book_details{$isbn}{'=default_search='} = ($book_details{$isbn}{title} || '')."\n".($book_details{$isbn}{authors} || '');
		}
		foreach $search_term (@search_terms) {
			my $search_type = "=default_search=";
			my $term = $search_term;
			if ($search_term =~ /([^:]+):(.*)/) {
				$search_type = $1;
				$term = $2;
			}
			while ($term =~ s/<([^">]*)"[^"]*"([^>]*)>/<$1 $2>/g) {}
			$term =~ s/<[^>]+>/ /g;
			next if $term !~ /\w/;
			$term =~ s/^\W+//g;
			$term =~ s/\W+$//g;
			$term =~ s/[^\w\n]+/\\b +\\b/g;
			$term =~ s/^/\\b/g;
			$term =~ s/$/\\b/g;
			next BOOK if !defined $book_details{$isbn}{$search_type};
			my $match;
			eval {
				my $field = $book_details{$isbn}{$search_type};
				# remove text that looks like HTML tags (not perfect)
				while ($field =~ s/<([^">]*)"[^"]*"([^>]*)>/<$1 $2>/g) {}
				$field =~ s/<[^>]+>/ /g;
				$field =~ s/[^\w\n]+/ /g;
				$match = $field !~ /$term/i;
			};
			if ($@) {
				$last_error = $@;
				$last_error =~ s/;.*//;
				return (); 
			}
			next BOOK if $match;
			$n_matches++;
		}
		push @matches, $isbn if $n_matches > 0;
	}
	
	sub bySalesRank {
		my $max_sales_rank = 100000000;
		my $s1 = $book_details{$a}{SalesRank} || $max_sales_rank;
		my $s2 = $book_details{$b}{SalesRank} || $max_sales_rank;
		return $a cmp $b if $s1 == $s2;
		return $s1 <=> $s2;
	}
	
	return sort bySalesRank @matches;
}

1
