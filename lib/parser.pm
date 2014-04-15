package lib::parser ;

use strict;
use warnings;

use Data::Dumper;
use Carp ;

use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = "1.0";
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw( get_oxidation_ref get_neutral_loss_ref set_category set_class set_subclass );
%EXPORT_TAGS = ( ALL => [qw( get_oxidation_ref get_neutral_loss_ref set_category set_class set_subclass )] ) ;

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

=head2 METHOD get_oxidation_ref

	## Description : get oxidation type and oxidation modification from conf file
	## Input : $CONF
	## Output : $list_oxidations, $list_ox_values
	## Usage : my ( $list_oxidations, $list_ox_values ) = get_oxidation_ref( $CONF, $selected_ox ) ;
	
=cut
## START of SUB
sub get_oxidation_ref {
	## Retrieve Values
    my $self = shift ;
    my ( $CONF, $selected_ox ) = @_ ;
    
    my @list_oxidations = () ;
    my @clean_list_oxidations = () ;
	my @list_ox_values = () ;
	
    if ( defined $selected_ox ) {
    	
	    @list_oxidations = split( /,/, $selected_ox ) ;
	    my $pos = 0 ; ## manage the splice
	    
	    foreach my $ox ( @list_oxidations  ) {
			if ($ox !~/NA$/ ) { ## case of ox
				push(@clean_list_oxidations, $ox) ;
				if		( $ox =~/^loss_(.*)/ ) 	{ push ( @list_ox_values, ($CONF->{$1}) ) ; }
				elsif	( $ox =~/^add_(.*)/ )  	{ push ( @list_ox_values, -($CONF->{$1}) ) ; } ### carefull of the number sign
				else { 								warn "This oxidation ($ox) is unknown in conf and menu\n" ; }
			}
			else { # if atoms eq NA, splice it
				next ;
			}
			$pos++ ;
		}
    }
    return(\@clean_list_oxidations, \@list_ox_values) ;
}
## END of SUB

=head2 METHOD get_neutral_loss_ref

	## Description : get neutral loss type and neutral loss modifications from conf file
	## Input : $CONF
	## Output : $list_neutral_losses, $list_nloss_values
	## Usage : my ( $list_neutral_losses, $list_nloss_values ) = get_neutral_loss_ref( $CONF, $selected_nloss ) ;
	
=cut
## START of SUB
sub get_neutral_loss_ref {
	## Retrieve Values
    my $self = shift ;
    my ( $CONF, $selected_nloss ) = @_ ;
    
    my @list_neutral_losses = () ; ## complete list
    my @clean_list_neutral_losses = () ; # list without NA
	my @list_nloss_values = () ; # values
    
    if ( defined $selected_nloss ) {
	    @list_neutral_losses = split( /,/, $selected_nloss ) ;

	    foreach my $nloss ( @list_neutral_losses  ) {
	    	
			if ($nloss !~/NA$/ ) { ## case of neutral loss
				push(@clean_list_neutral_losses, $nloss) ;
				if		( $nloss =~/^loss_(.*)/ ) 	{ push ( @list_nloss_values, ($CONF->{$1}) ) ; }
				elsif	( $nloss =~/^add_(.*)/ )  	{ push ( @list_nloss_values, -($CONF->{$1}) ) ; } ### carefull of the number sign
				else { 									warn "This neutral loss ($nloss) is unknown in conf and menu\n" ; }
			}
			else { # if atoms eq NA, splice it
				next ;
			}
		}
    }
    return(\@clean_list_neutral_losses, \@list_nloss_values) ;
}
## END of SUB

=head2 METHOD set_category

	## Description : set the category id from any types of ids
	## Input : $unknown_id
	## Output : $cat_id
	## Usage : my ( $cat_id ) = set_category( $unknown_id ) ;
	
=cut
## START of SUB
sub set_category {
	## Retrieve Values
    my $self = shift ;
    my ( $unknown_id ) = @_ ;
    my $cat_id = undef ;
    
    if ( defined $unknown_id ) {
    	if ( $unknown_id > 0 ) {
    		if ( (length $unknown_id) == 1 )  { $cat_id = $unknown_id }
    		elsif ( (length $unknown_id) == 3 )  { $cat_id = substr($unknown_id, 0, 1) }
    		elsif ( (length $unknown_id) == 5 )  { $cat_id = substr($unknown_id, 0, 1) }
    	}
    }
    else {
    	warn "Can't find any id to substr\n" ;
    }
    return( \$cat_id ) ;
}
## END of SUB

=head2 METHOD set_class

	## Description : set the class id from any types of ids
	## Input : $unknown_id
	## Output : $class_id
	## Usage : my ( $class_id ) = set_category( $unknown_id ) ;
	
=cut
## START of SUB
sub set_class {
	## Retrieve Values
    my $self = shift ;
    my ( $unknown_id ) = @_ ;
    my $class_id = undef ;
    
    if ( defined $unknown_id ) {
    	if ( $unknown_id > 0 ) {
    		if ( (length $unknown_id) == 3 )  { $class_id = $unknown_id }
    		elsif ( (length $unknown_id) == 5 )  { $class_id = substr($unknown_id, 0, 3) }
    	}
    }
    else {
    	warn "Can't find any id to substr\n" ;
    }
    return( \$class_id ) ;
}
## END of SUB

=head2 METHOD set_subclass

	## Description : set the subclass id from any types of ids
	## Input : $unknown_id
	## Output : $subclass_id
	## Usage : my ( $subclass_id ) = set_subclass( $unknown_id ) ;
	
=cut
## START of SUB
sub set_subclass {
	## Retrieve Values
    my $self = shift ;
    my ( $unknown_id ) = @_ ;
    my $subclass_id = undef ;
    
    if ( defined $unknown_id ) {
    	if ( $unknown_id > 0 ) {
    		if ( (length $unknown_id) == 5 )  { $subclass_id = $unknown_id }
    	}
    }
    else {
    	warn "Can't find any id to substr\n" ;
    } 
    return( \$subclass_id ) ;
}
## END of SUB



1 ;


__END__

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc XXX.pm

=head1 Exports

=over 4

=item :ALL is ...

=back

=head1 AUTHOR

Franck Giacomoni E<lt>franck.giacomoni@clermont.inra.frE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

version 1 : xx / xx / 201x

version 2 : ??

=cut