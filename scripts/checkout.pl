# finalize specified order

sub finalize_order {
	my $order_number = 0;
	$order_number++ while -r "$orders_dir/$username.$order_number";
	my %basket = read_basket();
	if (%basket) {
		open ORDER, ">$orders_dir/$username.$order_number";
		print ORDER "order_time=".time()."\n";
		foreach $isbn (keys %basket) {
			print ORDER "$isbn $basket{$isbn}\n";
		}
		close(ORDER);
		unlink "$baskets_dir/$username";	
	}
}

1
