package lib::operations ;

use strict;
use warnings ;
use Exporter ;
use Carp ;
use Data::Dumper ;

use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS);

our $VERSION = "1.0";
our @ISA = qw(Exporter);
our @EXPORT = qw( get_factorial truncate_num truncate_nums round_num round_nums );
our %EXPORT_TAGS = ( ALL => [qw( get_factorial truncate_num truncate_nums round_num round_nums )] );

=head1 NAME

My::operations - An example module

=head1 SYNOPSIS

    use My::operations;
    my $object = My::Module->new();
    print $object->as_string;

=head1 DESCRIPTION

This module clusters several more used maths functions like factorial...

=head1 METHODS

Methods are :

=head2 METHOD new

	## Description : new
	## Input : $self
	## Ouput : bless $self ;
	## Usage : new() ;

=cut

sub new {
    ## Variables
    my $self={};
    bless($self) ;
    return $self ;
}
### END of SUB

=head2 METHOD get_factorial

	## Description :permet de retourner la factorielle d'un nombre
	## Input : $indice
	## Output : $factorial
	## Usage : my ( var2 ) = get_factorial( var1 ) ;
	
=cut
## START of SUB
sub get_factorial {
	## Retrieve Values
    my $self = shift ;
    my ( $ind )= @_  ; # transmission des parametres
	my ( $factorial, $indmun ) = ( 0, 0 ) ;
	
	if ( defined $ind ) {
		
		if ( $ind == 0 ) {
			$factorial = 1 ;
		} 
		else {
			$indmun = $ind-1 ;
			$factorial = &get_factorial ( $self, $indmun ) * $ind ;
		}
	}
	else {
		croak "Indice in \"get_factorial sub\" is undef\n" ;
	}
	
	return ($factorial) ; # renvoi de la valeur
}
## END of SUB

=head2 METHOD truncate_num

	## Description : truncate a number by the sended decimal
	## Input : $number, $decimal
	## Output : $trunk_num
	## Usage : my ( $trunk_num ) = truncate_num( $number, $decimal ) ;
	
=cut
## START of SUB 
sub truncate_num {
    ## Retrieve Values
    my $self = shift ;
    my ( $number, $decimal ) = @_ ;
    my $trunk_num = 0 ;
    
	if ( ( defined $decimal ) and ( $decimal > 0 ) and ( defined $number ) and ( $number > 0 ) ) {
        $trunk_num = ($number =~ m/(\d+[\.|,]\d{$decimal})/);	## on utilise une tronquature seche 5.3 -> 5 et 5.8 -> 5
	    if($number =~/^\-/) {$trunk_num = -$trunk_num ;} # For neg number
	}
	else {
		croak "Can't trunk any number : missing value or decimal\n" ;
	}
    
    return(\$trunk_num) ;
}
## END of SUB

=head2 METHOD truncate_nums

	## Description : truncate a list of numbers by the sended decimal
	## Input : $numbers, $decimal
	## Output : $trunk_nums
	## Usage : my ( $trunk_nums ) = truncate_nums( $numbers, $decimal ) ;
	
=cut
## START of SUB 
sub truncate_nums {
    ## Retrieve Values
    my $self = shift ;
    my ( $numbers, $decimal ) = @_ ;
    my @trunk_nums = () ;
    
    if ( ( defined $decimal ) and ( $decimal > 0 ) and ( defined $numbers ) and ( scalar(@{$numbers}) > 0 ) ) {
    	foreach my $nb ( @{$numbers} ) {
	    	my ( $trunk_num ) = ( $nb =~ m/(\d+[\.|,]\d{$decimal})/ );	## on utilise une tronquature seche 5.3 -> 5 et 5.8 -> 5
	    	if( $nb =~/^\-/ ) { $trunk_num = -$trunk_num ; } # For neg number
	    	push ( @trunk_nums, $trunk_num ) ;
	    }
    }
    else {
    	croak "Can't trunk any number : missing values or decimal\n" ;
    }
    return( \@trunk_nums ) ;
}
## END of SUB

=head2 METHOD round_num

	## Description : round a number by the sended decimal
	## Input : $number, $decimal
	## Output : $round_num
	## Usage : my ( $round_num ) = round_num( $number, $decimal ) ;
	
=cut
## START of SUB 
sub round_num {
    ## Retrieve Values
    my $self = shift ;
    my ( $number, $decimal ) = @_ ;
    my $round_num = 0 ;
    
	if ( ( defined $decimal ) and ( $decimal > 0 ) and ( defined $number ) and ( $number > 0 ) ) {
        $round_num = sprintf("%.".$decimal."f", $number);	## on utilise un arrondit : 5.3 -> 5 et 5.5 -> 6
	}
	else {
		croak "Can't round any number : missing value or decimal\n" ;
	}
    
    return(\$round_num) ;
}
## END of SUB

=head2 METHOD round_nums

	## Description : round a list of numbers by the sended decimal
	## Input : $numbers, $decimal
	## Output : $round_nums
	## Usage : my ( $round_nums ) = round_nums( $numbers, $decimal ) ;
	
=cut
## START of SUB 
sub round_nums {
    ## Retrieve Values
    my $self = shift ;
    my ( $numbers, $decimal ) = @_ ;
    my @round_nums = () ;
    
#    print Dumper $numbers ;
    
    if ( ( defined $decimal ) and ( $decimal >= 0 ) and ( defined $numbers ) and ( scalar(@{$numbers}) > 0 ) ) {
    	foreach my $nb ( @{$numbers} ) {
    		if ( ( defined $nb ) ) {
    			if ($nb =~ /^\d+\.\d+$/  ) { ## check float
    				my $round_num = sprintf("%.".$decimal."f", $nb);	## on utilise un arrondit : 5.3 -> 5 et 5.5 -> 6 mais 5.25 -> 5.2
	    			push ( @round_nums, $round_num ) ;
    			}
    			else {
    				warn "This var $nb is not a float\n" ;
    			}
    		}
    		else {
    			croak "This number is not defined or is a string\n ";
    		}
	    	
	    }
    }
    else {
    	croak "Can't round any numbers : missing values or decimal\n" ;
    }
    return( \@round_nums ) ;
}
## END of SUB

=head2 METHOD subtract_num

	## Description : subtracting a number to an other
	## Input : $number, $number_to_subtr
	## Output : $value
	## Usage : my ( $value ) = subtract_num( $number, $number_to_subtr ) ;
	
=cut
## START of SUB
sub subtract_num {
	## Retrieve Values
    my $self = shift ;
    my ( $number, $number_to_subtr ) = @_ ;
    my $value = 0 ;
    
    if ( ( defined $number ) and ( defined $number_to_subtr ) ) {
		$value = ($number - $number_to_subtr) ;
    }
    else {
    	warn "The \n" ;
    }
    return(\$value) ;
}
## END of SUB

=head2 METHOD subtract_nums

	## Description : subtracting a number to a list of numbers
	## Input : $numbers, $numbers_to_subtr
	## Output : $values
	## Usage : my ( $values ) = subtract_num( $numbers, $numbers_to_subtr ) ;
	
=cut
## START of SUB
sub subtract_nums {
	## Retrieve Values
    my $self = shift ;
    my ( $numbers, $number_to_subtr ) = @_ ;
    my @values = () ;
    
    if ( ( defined $numbers ) and  ( defined $number_to_subtr ) ) {
   		foreach my $num ( @{$numbers} ) { push ( @values, ( $num - $number_to_subtr ) ) ; }
    }
    return(\@values) ;
}
## END of SUB

1 ;


__END__

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc operations.pm

=head1 Exports

=over 4

=item :ALL is get_factorial truncate_num truncate_nums round_num round_nums

=back

=head1 AUTHOR

Franck Giacomoni E<lt>franck.giacomoni@clermont.inra.frE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

version 1 : 29 / 04 / 2013

version 2 : ??

=cut