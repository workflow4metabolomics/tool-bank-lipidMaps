package lib::lmTest ;

use diagnostics; # this gives you more debugging information
use warnings;    # this warns you of bad practices
use strict;      # this prevents silly errors
use Exporter ;
use Carp ;

use Data::Dumper ;

our $VERSION = "1.0";
our @ISA = qw(Exporter);
our @EXPORT = qw( build_lm_mass_queryTest round_numsTest );
our %EXPORT_TAGS = ( ALL => [qw( build_lm_mass_queryTest round_numsTest )] );

use lib '/Users/fgiacomoni/Inra/labs/perl/galaxy_tools/lipidmaps' ;
use lib::lipidmaps qw( :ALL ) ;
use lib::operations qw( :ALL ) ;

sub build_lm_mass_queryTest {
	
	my ( $delta, $selected_cat, $selected_cl, $selected_subcl ) = @_ ;
	my ( $cat, $cl, $subcl ) = (undef, undef, undef) ; 
	my $url = 'http://www.lipidmaps.org/data/structure/LMSDSearch.php?Mode=ProcessTextSearch&OutputColumnHeader=No&OutputMode=File&OutputType=TSV' ;
	
	if ( ( defined $selected_subcl) or ( defined $selected_cl ) or ( defined $selected_cat ) ) {
		if ( ( $selected_cat !~ /^NA/ ) ) { ( $cat ) = ( \$selected_cat ) ; }
		if ( ( $selected_cl !~ /^NA(.*)/ ) ) { ( $cl ) = ( \$selected_cl ) ; }
		if ( ( $selected_subcl !~ /^NA(.*)/ ) ) { ( $subcl ) = ( \$selected_subcl ) ; }
	}
	else { croak "No selected category or classification ids list\n" ; }
	
	
	my $olm = lib::lipidmaps->new() ;
	my $ref_url = $olm->build_lm_mass_query(\$url, \$delta, $cat, $cl, $subcl) ;
	my $complete_url = $$ref_url ;
#	print $complete_url ;
	return ($complete_url) ;
}

## SUB TEST for 
sub round_numsTest {
    # get values
    my ( $numbers, $decimal ) = @_;
    
    my $oround = lib::operations->new() ;
    my $rounds = $oround->round_nums($numbers, $decimal) ;
    
    return($rounds) ;
}
## End SUB


1 ;