sub basket_page {
	my %basket = read_basket();
	
	open F, "html/basket_table_head.html";
	my @lines = <F>;
	print "<div class=\"pagination pagination-centered\">	<h3>$username</h3></div>";
	print join "",@lines;
	close F;
	foreach my $isbn (sort keys %basket) {
		my %table_variables = (isbn => $isbn, title =>$book_details{$isbn}{'title'}, quantity=> $basket{$isbn},
		authors =>$book_details{$isbn}{'authors'}, price =>$book_details{$isbn}{'price'});
		my $table = HTML::Template->new(filename => "html/basket_table.template", die_on_bad_params => 0);
		$table->param(%table_variables);
		print $table->output;
	}	
	my $tail = HTML::Template->new(filename => "html/basket_table_tail.template", die_on_bad_params => 0);
	my %tail_variables = (total => total_basket(%basket)) if %basket;
	$tail->param(%tail_variables);
	print $tail->output;
	close F;

	#orders
	my %orders = read_orders();
	open F, "html/order_table_head.html";
	my @lines = <F>;;
	print join "",@lines;
	close F;
	
	foreach my $order_num (sort keys %orders) {
		foreach my $isbn (sort keys %{$orders{$order_num}}) {
			my %table_variables = (isbn => $isbn, title =>$book_details{$isbn}{'title'}, quantity=> $orders{$order_num}{$isbn},
			authors =>$book_details{$isbn}{'authors'}, price =>$book_details{$isbn}{'price'}, order_num => $order_num);
			my $table = HTML::Template->new(filename => "html/order_table.template", die_on_bad_params => 0);
			$table->param(%table_variables);
			print $table->output;
		}
	}	

	open F, "html/order_table_tail.html";
	@lines = <F>;;
	print join "",@lines;
	close F;
	
}

sub read_orders {
	my %orders;	
	my $order_number = 0;
	while (-r "$orders_dir/$username.$order_number") {
		open F, "$orders_dir/$username.$order_number";
		my $time = <F>;
		while (<F>) {
			$_ =~ /(\w{10}) (\d+)/;
			$orders{$order_number}{$1} = $2;
		}
		close F;
		$order_number++;
	}
	return %orders;
}

# Returns total of amount in basket

sub total_basket {
	my (%basket) = @_;
	my $total;
	foreach my $isbn (keys %basket) {
		$book_details{$isbn}{'price'} =~ /\$(\d+\.\d+)/;
		$total += $basket{$isbn}*$1;
	}
	$total = "\$".$total;
	return $total;
}

# return books in specified user's basket

sub read_basket {
	our %book_details;
	my %basket;
	open F, "$baskets_dir/$username" or return ();
	while(<F>) {
		$_ =~ /(\d{9}\w) (\d+)/;
		$basket{$1} = $2 if defined $1;
	}
	close(F);
	return %basket;
}


# delete specified book from specified user's basket

sub delete_basket {
	my ($delete_isbn) = @_;

	my %basket = read_basket($username);
	
	foreach $isbn (keys %basket) {
		if ($isbn eq $delete_isbn) {
			delete $basket{$isbn};
			next;
		}
	}
	write_basket(%basket);
}




sub write_basket {
	my (%basket) = @_;
	open F, ">$baskets_dir/$username" or die "Can not open $baskets_dir/$username: $!";
	foreach $isbn (keys %basket) {
		print F "$isbn $basket{$isbn}\n";
	}
	close(F);
	if (! -s "$baskets_dir/$username") {
		unlink "$baskets_dir/$username"; 
	}
}

# add specified book to specified user's basket

sub add_basket {
	my ($add_isbn, $quantity) = @_;
	if ($valid) {
		my %basket = read_basket();
		foreach $isbn (keys %basket) {
			if ($isbn eq $add_isbn) {
				$basket{$isbn} += $quantity;
				break;
			}
		}
		$basket{$add_isbn} = $quantity if (! defined $basket{$add_isbn});
		write_basket(%basket);
	}
}
1
