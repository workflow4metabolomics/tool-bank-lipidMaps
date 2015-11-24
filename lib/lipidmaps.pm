package lib::lipidmaps ;

use strict;
use warnings;

use Data::Dumper;
use Carp ;
use LWP::UserAgent ;

use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = "1.0";
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(set_total_carbons get_elts_from_lm_common_name);
%EXPORT_TAGS = ( ALL => [qw(set_total_carbons get_elts_from_lm_common_name)] ) ;


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

=head2 METHOD build_lm_mass_query

	## Description : set the query from the lipdmaps WS
	## Input : $url, $delta, $cat, $cl, $subcl 
	## Output : $query
	## Usage : my ( $query ) = build_lm_mass_query( $url, $delta, $cat, $cl, $subcl  ) ;
	
=cut
## START of SUB
sub build_lm_mass_query {
	## Retrieve Values
    my $self = shift ;
    my ( $url, $delta, $cat, $cl, $subcl  ) = @_ ;
    my $query = undef ;
    ## build the REST query like : 
    #'http://www.lipidmaps.org/data/structure/LMSDSearch.php?
    #Mode=ProcessTextSearch&OutputMode=File&OutputType=TSV&CoreClass=3&MainClass=303&SubClass=30301&ExactMass=1000.05&ExactMassOffSet=0.5'
    
    if ( defined $url ) {
    	$query = $$url ;
    	if ( defined $$cat ) { $query.= '&CoreClass='.$$cat ; }
	    if ( defined $$cl ) { $query .= '&MainClass='.$$cl ; }
	    if ( defined $$subcl ) { $query .= '&SubClass='.$$subcl ; }
	    if ( defined $delta ) { $query .= '&ExactMassOffSet='.$$delta ; }
	    ## and prepare the mass param :
	    $query .= '&ExactMass=' ;
    }
    else {
    	croak "Can't find any url to buil your query\n" ;
    }
    return(\$query) ;
}
## END of SUB

=head2 METHOD get_lm_mass_query

	## Description : get the builded query on LM WS
	## Input : $query, $mass
	## Output : $result
	## Usage : my ( $result ) = get_lm_mass_query( $query, $mass ) ;
	
=cut
## START of SUB
sub get_lm_mass_query {
	## Retrieve Values
    my $self = shift ;
    my ( $query, $mass ) = @_ ;
    
    my $result = undef ;
    my $rest_query = $$query.$$mass ;
    
#    print "QUERY_".$rest_query."_STOP\n" ;
    my $browser = LWP::UserAgent->new;
    $result = $browser->get($rest_query) ;
	die "Can't GET the folowing mz query: $rest_query!" if ( ! defined $rest_query ) ;
	
	if ($result->is_error) {
		croak "$result->status_line \n" ;
	}
#	else {
#		print Dumper $result->content ;
#	}

    return(\$result->content, \$rest_query) ;
}
## END of SUB

=head2 METHOD get_lm_entry_object

	## Description : build a list of lm_entry_objects from a raw result 
	## Input : $result
	## Output : $entry_objects
	## Usage : my ( $entry_objects ) = get_lm_entry_object( $result ) ;
	
=cut
## START of SUB
sub get_lm_entry_object {
	## Retrieve Values
    my $self = shift ;
    my ( $result, $q_mass ) = @_ ;
    
    my @entry_objects = () ;
    my $nb_entries = 0 ;
    my $qmass = $$q_mass ;
    
    if ( defined $result ) {
    	my @entries = split (/\n|\r/, $$result) ;
    	$nb_entries = scalar(@entries) ;
    	foreach my $entry (@entries) {
	    	my %entry = ( ID => undef, COMMON_NAME => undef, SYST_NAME => undef, FORMULA => undef, MASS => undef ) ;
	    	
	    	$entry{ID} = $self->get_lm_id(\$entry) ;
	    	$entry{COMMON_NAME} = $self->get_lm_common_name(\$entry) ;
	    	$entry{SYST_NAME} = $self->get_lm_systematic_name(\$entry) ;
	    	$entry{FORMULA} = $self->get_lm_formula(\$entry) ;
	    	$entry{MASS} = $self->get_lm_mass(\$entry) ;
	    	
	    	## delta 
	    	$entry{QMASS} = $qmass ;
	    	$entry{DELTA} = $self->delta_mass(\$qmass, $entry{MASS} ) ;
	    	push (@entry_objects, \%entry) ;
	    }
    } ## END IF
    else {
    	croak "Can't manage a an empty result and produce a entry object\n" ;
    }
    return(\@entry_objects, \$nb_entries) ;
}
## END of SUB

=head2 METHOD get_cluster_object

	## Description : build a list of clusters objects from a entry_object (list of hash) using a list oh parsing rules decrived in CONF file
	## Input : $entries_result, $RULES
	## Output : $clusters_object
	## Usage : my ( $clusters_object ) = get_cluster_object( $entries_result, $RULES ) ;
	
=cut
## START of SUB
sub get_cluster_object {
	## Retrieve Values
    my $self = shift ;
    my ( $entries_result, $RULES, $RECIPES ) = @_ ;
    
    my (@pre_clustering) = ( () ) ;
    my $clusters_object = undef ;
    
    if ( ( defined $entries_result ) and ( defined $RULES )) {
    	
    	foreach my $entry (@$entries_result) {
    		my %cluster = ( CLUSTER_DELTA => undef, CLUSTER_NAME => undef, FORMULA => undef, ISOTOPIC_RATIO => undef, NB_ENTRIES_FOR_CLUSTER => 0, ENTRY_IDS => undef ) ;
    		
    		## get features
    		my ($g1,$g2,$g3,$c1,$i1,$c2,$i2,$c3,$i3,$ox,$post) = $self->parse_lm_common_name($entry->{COMMON_NAME}, $RULES, $RECIPES) ;

    		my ( $total_c ) = $self->set_total_carbons($c1, $c2, $c3) ;
    		my ( $total_i ) = $self->set_total_insaturations($i1, $i2, $i3) ;
    		my ( $group ) =  $self->set_group($g1, $g2, $g3) ;
    		
    		## set cluster object
    		$cluster{CLUSTER_NAME} = $self->set_cluster_name($group, $total_c, $total_i, \$ox, \$post, $entry->{COMMON_NAME} ) ;
    		$entry->{CLUSTER_NAME} = $cluster{CLUSTER_NAME} ;
    		$cluster{CLUSTER_DELTA} = $entry->{DELTA} ;
    		$cluster{FORMULA} = $entry->{FORMULA} ;
    		$cluster{ISOTOPIC_RATIO} = 'N/A' ; ## compute isotopic ratio
    		$cluster{NB_ENTRIES_FOR_CLUSTER} = 1 ;
    		$cluster{ENTRY_IDS} = $entry->{ID} ;
    		
    		push (@pre_clustering, \%cluster) ;
    	}
    	
    	## Pool cluster objects by cluster name
	    $clusters_object = $self->pool_cluster_objects(\@pre_clustering) ;
    	
    }
    else {
    	croak "Can't manage a an empty entries result and produce a cluster object\n" ;
    }
    
    return($clusters_object) ;
}
## END of SUB

=head2 METHOD get_lm_id

	## Description : retrieve the following param in the formatted output
	## Input : $content
	## Output : $LM_id
	## Usage : my ( $LM_id ) = get_lm_id( $separator, $content ) ;
	
=cut
## START of SUB
sub get_lm_id {
	## Retrieve Values
    my $self = shift ;
    my ( $content ) = @_ ;
    my $LM_id = undef ;
    my $entry = ${$content} ;
    if ( $entry =~ /^LM[A-Z](.*)/ ) {
    	##$1=LM_ID	$2=COMMON_NAME	$3=SYSTEMATIC_NAME	$4=FORMULA	$5=MASS	$6=CATEGORY	$7=MAIN_CLASS	$8=SUB_CLASS
		if ( $entry =~ /^(\w+)\t(.*)/ ) { $LM_id = $1 ;	}
    }
    else {
    	carp "The submitted entry is not at the right format : $entry\n" ;
    }
    return(\$LM_id) ;
}
## END of SUB

=head2 METHOD get_lm_common_name

	## Description : retrieve the following param in the formatted output
	## Input : $content
	## Output : $common_name
	## Usage : my ( $common_name ) = get_lm_common_name( $separator, $content ) ;
	
=cut
## START of SUB
sub get_lm_common_name {
	## Retrieve Values
    my $self = shift ;
    my ( $content ) = @_ ;
    my $common_name = undef ;
	my $entry = ${$content} ;
    if ( $entry =~ /^LM[A-Z](.*)/ ) {
    	##$1=LM_ID	$2=COMMON_NAME	$3=SYSTEMATIC_NAME	$4=FORMULA	$5=MASS	$6=CATEGORY	$7=MAIN_CLASS	$8=SUB_CLASS
		if ( $entry =~ /^(\w+)\t(.*)\t(.*)\t(.*)\t(.*)\t(.*)\t(.*)\t(.*)/ ) { $common_name = $2 ; }
    }
    else {
    	carp "The submitted entry is not at the right format : $entry\n" ;
    } 
    return(\$common_name) ;
}
## END of SUB

=head2 METHOD get_lm_systematic_name

	## Description : retrieve the following param in the formatted output
	## Input : $separator, $content
	## Output : $common_name
	## Usage : my ( $common_name ) = get_lm_systematic_name( $separator, $content ) ;
	
=cut
## START of SUB
sub get_lm_systematic_name {
	## Retrieve Values
    my $self = shift ;
    my ( $content ) = @_ ;
    my $systematic_name = undef ;
    my $entry = ${$content} ;
    if ( $entry =~ /^LM[A-Z](.*)/ ) {
    	##$1=LM_ID	$2=COMMON_NAME	$3=SYSTEMATIC_NAME	$4=FORMULA	$5=MASS	$6=CATEGORY	$7=MAIN_CLASS	$8=SUB_CLASS
		if ( $entry =~ /^(\w+)\t(.*)\t(.*)\t(.*)\t(.*)\t(.*)\t(.*)\t(.*)/ ) { $systematic_name = $3 ; }
    }
    else {
    	carp "The submitted entry is not at the right format : $entry\n" ;
    }
    return(\$systematic_name) ;
}
## END of SUB

=head2 METHOD get_lm_formula

	## Description : retrieve the following param $formula in the formatted output
	## Input : $content
	## Output : $formula
	## Usage : my ( $formula ) = get_lm_systematic_name( $separator, $content ) ;
	
=cut
## START of SUB
sub get_lm_formula {
	## Retrieve Values
    my $self = shift ;
    my ( $content ) = @_ ;
    my $formula = undef ;
    my $entry = ${$content} ;
    if ( $entry =~ /^LM[A-Z](.*)/ ) {
    	##$1=LM_ID	$2=COMMON_NAME	$3=SYSTEMATIC_NAME	$4=FORMULA	$5=MASS	$6=CATEGORY	$7=MAIN_CLASS	$8=SUB_CLASS
		if ( $entry =~ /^(\w+)\t(.*)\t(.*)\t(.*)\t(.*)\t(.*)\t(.*)\t(.*)/ ) { $formula = $4 ; }
    }
    else {
    	carp "The submitted entry is not at the right format : $entry\n" ;
    }
    return(\$formula) ;
}
## END of SUB

=head2 METHOD get_lm_mass

	## Description : retrieve the following param $mass in the formatted output
	## Input : $content
	## Output : $mass
	## Usage : my ( $mass ) = get_lm_mass( $separator, $content ) ;
	
=cut
## START of SUB
sub get_lm_mass {
	## Retrieve Values
    my $self = shift ;
    my ( $content ) = @_ ;
    my $mass = undef ;
    my $entry = ${$content} ;
    if ( $entry =~ /^LM[A-Z](.*)/ ) {
    	##$1=LM_ID	$2=COMMON_NAME	$3=SYSTEMATIC_NAME	$4=FORMULA	$5=MASS	$6=CATEGORY	$7=MAIN_CLASS	$8=SUB_CLASS
		if ( $entry =~ /^(\w+)\t(.*)\t(.*)\t(.*)\t(.*)\t(.*)\t(.*)\t(.*)/ ) { $mass = $5 ; }
    }
    else {
    	carp "The submitted entry is not at the right format : $entry\n" ;
    }
    return(\$mass) ;
}
## END of SUB

=head2 METHOD delta_mass

	## Description : compute a delta between the query mass and cpd mass
	## Input : $q_mass, $cpd_mass
	## Output : $delta_mass
	## Usage : my ( $delta_mass ) = delta_mass( $q_mass, $cpd_mass ) ;
	
=cut
## START of SUB
sub delta_mass {
	## Retrieve Values
    my $self = shift ;
    my ( $q_mass, $cpd_mass ) = @_ ;
    
    my $delta_mass = 0 ;
    
    if ( ( defined $$q_mass ) and ( defined $$cpd_mass ) and ( $$q_mass > 0 ) and ( $$cpd_mass > 0 )  ) {
    	my $delta =  $$cpd_mass - $$q_mass;
    	$delta_mass = sprintf("%.2f", $delta );
    } ## END IF
    else {
    	croak "Provided masses are not defined or equal to zero\n" ;
    }
    
    
    return(\$delta_mass) ;
}
## END of SUB

=head2 METHOD get_elts_from_lm_common_name

	## Description : get group, numbers of carbons, insaturation and oxydations in LM common name and return a 'cluster' name.
	## Input : $lm_common_name, $RULES, $RECIPES
	## Output : $Gp1, $Gp2, $Gp3, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ch3_C, $Ch3_i, $Ox, $Post
	## Usage : my ( $Gp1, $Gp2, $Gp3, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ch3_C, $Ch3_i, $Ox, $Post ) = get_elts_from_lm_common_name( $lm_common_name, $RULES, $RECIPES ) ;
	
=cut
## START of SUB
sub parse_lm_common_name {
	## Retrieve Values
    my $self = shift ;
    my ( $lm_common_name, $RULES, $RECIPES ) = @_ ;
    my ( $Gp1, $Gp2, $Gp3, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ch3_C, $Ch3_i, $Ox, $Post ) = ( undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef) ;
    my $rule_nb = 0 ;
    
    my $common_name = $$lm_common_name ;
    if (defined $common_name) {
		if( $common_name =~ /\s/ ) { 		$common_name =~ s/ //g ;  	} ## del all spaces		
		my @matches = (undef) ; # init first position at undef to manage undef regex
		
		## Goals :
		## - use each parsing rule on the common name 
		## - extrat the 9 values containing in the common name (value can be undef)
		## - translate initialized $Gp1, $Gp2, $Gp3, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ch3_C, $Ch3_i, $Ox, $Post values by real ones (ex; 0 => PE, or 0-1-4 => PS-O-P) 
		foreach my $rule (keys %{$RULES} ) {
			$rule =~ m/^RULE(\d+)/ ;
			$rule_nb = $1 ;
			push ( @matches, ($common_name =~ m/$RULES->{$rule}/g) ) ; # catch all matches in the regex
			
			my ($v1, $v2, $v3, $v4, $v5, $v6, $v7, $v8, $v9, $v10, $v11 ) = split(/,/, $RECIPES->{'RECIPE'.$rule_nb}) ;
			( $Gp1, $Gp2, $Gp3 ) = ( $matches[$v1], $matches[$v2], $matches[$v3] ) ;
			( $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ch3_C, $Ch3_i ) = ( $matches[$v4], $matches[$v5], $matches[$v6], $matches[$v7], $matches[$v8], $matches[$v9] ) ;
			( $Ox, $Post ) = ( $matches[$v10], $matches[$v11] ) ;
			if (scalar (@matches) > 1) { last ; } # get out of the loop
		}
    }
    else {
    	croak "No Common name to get in method get_elts_from_lm_common_name!\n" ;
    }
    return( $Gp1, $Gp2, $Gp3, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ch3_C, $Ch3_i, $Ox, $Post) ;
}
## END of SUB

=head2 METHOD set_total_carbons

	## Description : compute total number of carbons found in entry
	## Input : $Ch1_C, $Ch2_C, $Ch3_C
	## Output : $total_C
	## Usage : my ( $total_C ) = set_total_carbons( $Ch1_C, $Ch2_C, $Ch3_C ) ;
	
=cut
## START of SUB
sub set_total_carbons {
	## Retrieve Values
    my $self = shift ;
    my ( $Ch1_C, $Ch2_C, $Ch3_C ) = @_ ;    
    my $total_C = undef ;

	if 		( ( defined $Ch1_C ) and ( defined $Ch2_C ) and ( defined $Ch3_C ) ) { $total_C = ( $Ch1_C + $Ch2_C + $Ch3_C ) ; }
	elsif 	( ( defined $Ch1_C ) and ( defined $Ch2_C ) ) { $total_C = ( $Ch1_C + $Ch2_C ) ; 	}
	elsif 	( ( defined $Ch1_C ) ) 	{ $total_C = ( $Ch1_C ) ; 	}
	else 	{	( $total_C ) = ( undef ) ; 	}
    
    return(\$total_C) ;
}
## END of SUB

=head2 METHOD set_total_insaturations

	## Description : compute total number of insaturations found in entry
	## Input : $Ch1_i, $Ch2_i, $Ch3_i
	## Output : $total_i
	## Usage : my ( $total_i ) = set_total_insaturations( $Ch1_i, $Ch2_i, $Ch3_i ) ;
	
=cut
## START of SUB
sub set_total_insaturations {
	## Retrieve Values
    my $self = shift ;
    my ( $Ch1_i, $Ch2_i, $Ch3_i ) = @_ ;    
    my $total_i = undef ;

	if 		( ( defined $Ch1_i ) and ( defined $Ch2_i ) and ( defined $Ch3_i ) ) { $total_i = ( $Ch1_i + $Ch2_i + $Ch3_i ) ; }
	elsif 	( ( defined $Ch1_i ) and ( defined $Ch2_i ) ) { $total_i = ( $Ch1_i + $Ch2_i ) ; 	}
	elsif 	( ( defined $Ch1_i ) ) 	{ $total_i = ( $Ch1_i ) ; 	}
	else 	{	( $total_i ) = ( undef ) ; 	}
    
    return(\$total_i) ;
}
## END of SUB

=head2 METHOD set_group

	## Description : set a complete group when multiple 
	## Input : $Gp1, $Gp2, $Gp3
	## Output : $group
	## Usage : my ( $group ) = set_group( $Gp1, $Gp2, $Gp3 ) ;
	
=cut
## START of SUB
sub set_group {
	## Retrieve Values
    my $self = shift ;
    my ( $Gp1, $Gp2, $Gp3 ) = @_ ;
    my $group = undef ;
    
    if ( ( defined $Gp1 ) and ( defined $Gp2 ) and ( defined $Gp3 ) ) 	{	$group = $Gp1.'-'.$Gp2.'-'.$Gp3 ;    }
    elsif ( ( defined $Gp1 ) and ( defined $Gp2 )  ) {						$group = $Gp1.'-'.$Gp2 ; }
    elsif ( ( defined $Gp1 )  ) {											$group = $Gp1 ;  }
    else {    																$group = undef ; }
    
    return(\$group) ;
}
## END of SUB

=head2 METHOD set_cluster_name

	## Description : set the cluster name by concat $group / $total_c / $total_i / $ox / $post or use $common_name if no elt exist.
	## Input : $group, $total_c, $total_i, $ox, $post, $common_name
	## Output : $cluster_name
	## Usage : my ( $cluster_name ) = set_cluster_name( $group, $total_c, $total_i, $ox, $post ) ;
	
=cut
## START of SUB
sub set_cluster_name {
	## Retrieve Values
    my $self = shift ;
    my ( $group, $total_c, $total_i, $ox, $post, $common_name ) = @_ ;
    my $cluster_name = undef ;
    
    if ( ( defined $$total_c ) and ( defined $$total_i ) and ( defined $$group )  ) {
			$cluster_name = $$group.'_'.$$total_c.':'.$$total_i ;
			## OXIDATION AND REST
			if ( defined $$ox ) { $cluster_name = $cluster_name.'('.$$ox.')' ; }
			if ( defined $$post ) { $cluster_name = $cluster_name.$$post ;	}
		}
	elsif ( ( defined $$group ) ) { 	$cluster_name = $$group ; 			}
	else { $cluster_name = $$common_name ; }
    
    return(\$cluster_name) ;
}
## END of SUB

=head2 METHOD pool_cluster_objects

	## Description : pool all cluster objects in a same group by their cluster name (and formula)
	## Input : $cluster_objects
	## Output : $pool_objects
	## Usage : my ( $pool_objects ) = pool_cluster_objects( $cluster_objects ) ;
	
=cut
## START of SUB
sub pool_cluster_objects {
	## Retrieve Values
    my $self = shift ;
    my ( $cluster_objects ) = @_ ;
    
    my @pools = () ;
    my %sort = () ;
    
    # prerequis for the first iteration 
    my $ref_common_name = 'NONE' ; 
    
    # sort entries by cluster with a key hash system
    foreach my $object (@{$cluster_objects}) {
    	my %current = %{$object} ;
		my $q_name = $current{CLUSTER_NAME} ;
    	
    	## prepare data
    	if (  !defined $sort{$$q_name}{ENTRY_IDS} ) {
    		 $sort{$$q_name}{ENTRY_IDS} = [] ; 
    		 $sort{$$q_name}{NB_ENTRIES_FOR_CLUSTER} = 1 ;
    	}
    	else {
    		$sort{$$q_name}{NB_ENTRIES_FOR_CLUSTER} = ($sort{$$q_name}{NB_ENTRIES_FOR_CLUSTER}) + 1 ;
    	}
    	
    	## pool
    	if ( $$q_name ne $ref_common_name ) {
    		$sort{$$q_name}{CLUSTER_NAME} = $q_name ;
    		push ( @{ $sort{$$q_name}{ENTRY_IDS} }, $current{ENTRY_IDS} ) ;
    	}
    	else {
			push ( @{ $sort{$$q_name}{ENTRY_IDS} }, $current{ENTRY_IDS} ) ;
			next ;
		}
		## set rest of features
		$sort{$$q_name}{FORMULA} = $current{FORMULA} ;
		$sort{$$q_name}{ISOTOPIC_RATIO} = $current{ISOTOPIC_RATIO} ;
		$sort{$$q_name}{CLUSTER_DELTA} = $current{CLUSTER_DELTA} ;
    	
		$ref_common_name = $$q_name ;
    }
    # and pool them
    foreach ( keys %sort ) { push (@pools, $sort{$_}) ;  }
    
    return(\@pools) ;
}
## END of SUB

## Fonction : permet de retourner une somme de features pour un common name
## Input : $CommonName de type LM
## Ouput : $SimpleName
sub getSimpleNameFromCommonName {
    ## Retrieve Values
    my ( $CommonName ) = @_;
    my $SimpleName = undef ;
    
    if (defined $CommonName) {
    	## virer les espaces :
		if($CommonName =~ /\s/) { 		$CommonName =~ s/ //g ;  	}
		
		## Initialize all
		
		my ( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ch3_C, $Ch3_i, $Ox, $Post ) = ( undef, undef, undef, undef, undef, undef, undef, undef, undef ) ;
		
		if ( $CommonName =~/^\-$/) { ## RULE des '-' only
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( 'UnNamed_IN_LM', undef, undef, undef, undef, undef ) ;
		}
		## *** ***  PG  *** *** ##
		elsif ($CommonName =~/^([A-Z|a-z|0-9|\-]*)$/) { ## RULE des XX-xx only -- Ex: PE-NMe2 ou PC
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1, undef, undef, undef, undef, undef ) ;
		}
		elsif ( $CommonName =~/^([A-Z|a-z]{2,4})\((\d+):(\d+)\/(\d+):(\d+)\)$/) { ## RULE des XX(16:1/16:1)
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1, $2, $3, $4, $5, undef ) ;
		}
		elsif ( $CommonName =~/^([A-Z|a-z]{2,4})\((\d+):(\d+)\/(\d+):(\d+)\(([OHC]*)\)\)$/) { ## RULE des XX(16:1/16:1(OHC)) OXYDES!!
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1, $2, $3, $4, $5, $6 ) ;
		}
		elsif ( $CommonName =~/^([A-Z|a-z]{2,4})\((\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\(([OHCKe0-9]*)\)\)$/) { ## RULE des XX(16:1(1Z,..)/16:1(1Z,..)(OHC)) OXYDES!! -- Ex: PE(16:0/22:6(54Z,7Z,10Z,12E,16Z,19Z)(14OH))
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1, $2, $3, $4, $5, $6 ) ;
		}
		elsif ( $CommonName =~/^([A-Z|a-z]{2,4})\((\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\)$/) { ## RULE des XX(16:1(1Z,..)/16:1(1Z,..))
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1, $2, $3, $4, $5, undef ) ;
		}
		elsif ( $CommonName =~/^([A-Z|a-z]{2,5})\((\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\)$/) { ## RULE des XX(16:1(1Z,...)) ou XX(16:1) ONLY
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1, $2, $3, undef, undef, undef ) ;
		}
		elsif ( $CommonName =~/^([A-Z|a-z]{2,4})\(([A-Z]{1})-(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\)$/) { ## RULE des XX(X-16:1(1Z,..)/16:1(1Z,..))  avec (1Z,...) en option
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1.'-'.$2, $3, $4, $5, $6, undef ) ;
		}
		elsif ( $CommonName =~/^([A-Z|a-z]{2,4})\((\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/([A-Z]{1})-(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\)$/) { ## RULE des XX(16:1(1Z,..)/X-16:1(1Z,..))  avec (1Z,...) en option
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1.'-'.$4, $2, $3, $5, $6, undef ) ;
		}
		elsif ( $CommonName =~/^([A-Z|a-z]{2,4})\(([A-Z]{1})-(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/([A-Z]{1})-(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\)$/) { ## RULE des XX(X-16:1(1Z,..)/X-16:1(1Z,..)) avec (1Z,...) en option
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1.'-'.$2.'-'.$5, $3, $4, $6, $7, undef ) ;
		}
		elsif ( $CommonName =~/^([A-Z|a-z]*-[A-Z|a-z|0-9]*)\((\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\)$/) { ## RULE des XX-xx(16:1(1Z,..)/16:1(1Z,..))  -- Ex: PE-NMe(16:0/16:0)
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1, $2, $3, $4, $5, undef ) ;
		}
		elsif ( $CommonName =~/^([A-Z|a-z]*-[A-Z|a-z|0-9]*)\(([A-Z]{1})-(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/([A-Z]{1})-(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\)$/) { ## RULE des XX-xx(X-16:1(1Z,..)/X-16:1(1Z,..)) -- Ex: PE-NMe(O-16:0/O-16:0)
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1.'-'.$2.'-'.$5, $3, $4, $6, $7, undef ) ;
		}
		elsif ( $CommonName =~/^([a-z|A-Z|\-]*)\((\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\)$/) { ## RULE des XX-xx(16:1(1Z,)/16:1(1Z,)/16:1(1Z,...)) -- Ex: PS-NAc(18:0/18:1(9Z)/16:0)
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ch3_C, $Ch3_i, $Ox ) = ( $1, $2, $3, $4, $5, $6, $7, undef ) ;
		}
		elsif ( $CommonName =~/^([A-Z|a-z]{2,4})\((\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\)(\[[A-Z|a-z|0-9]*\])$/) { ## RULE des XX(16:1(1Z,..)/16:1(1Z,..))[Xx] -- Ex : PC(18:1(9Z)/0:0)[rac]
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox, $Post ) = ( $1, $2, $3, $4, $5, undef, $6 ) ;
		}
		elsif ( $CommonName =~/^([A-Z|a-z]{2,4})\((\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\)\(([A-Z|a-z|0-9|\[\]]*)\)\)$/) { ## RULE des XX(16:1(1Z,..)/16:1(1Z,..))(OHC[S]) -- Ex: PE(16:0/20:4(5Z,8Z,10E,14Z)(12OH[S]))  OXYDES!!
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1, $2, $3, $4, $5, $6 ) ;
		}
		elsif ( $CommonName =~/^([A-Z|a-z]{2,4})\(([A-Z]{1})-(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\)\(([A-Z|a-z|0-9|\[\]]*)\)\)$/) { ## RULE des XX(X-16:1(1Z,..)/16:1(1Z,..))(OHC[S]) -- Ex: PE(P-18:0/20:4(6E,8Z,11Z,14Z)(5OH[S]))  OXYDES!!
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1.'-'.$2, $3, $4, $5, $6, $7 ) ;
		}
		elsif ( $CommonName =~/^([A-Z|a-z|0-9|\[\]|',]*)\((\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\)$/) { ## RULE des XX[3',5'](16:1(1Z,..)/16:1(1Z,..))
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1, $2, $3, $4, $5, undef ) ;
		}
		## *** ***  *** *** SM  *** *** *** *** ##
		elsif ( $CommonName =~ /^([A-Za-z0-9\-]*)\([a-z](\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\(([COH0-9\-]*)\)\)$/ ) { ## RULE des xx-XX(16:1(1z..)/16:0(1z..)(OH)) -- Ex: PE-Cer(d16:2(4E,6E)/24:1(15Z)(2OH))  OXYDES !!
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1, $2, $3, $4, $5, $6 ) ;
		}
		elsif ( $CommonName =~ /^([A-Za-z0-9\-]*)\([a-z]{0,1}(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/[a-z]{0,1}(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\)$/ ) { ## RULE des xx-XX(16:1(1z..)/16:0(1z..)) -- Ex: GlcCer(d14:2(4E,6E)/18:1(9Z))
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1, $2, $3, $4, $5, undef ) ;
		}
		elsif ( $CommonName =~ /^(M\(IP\)2C)\([a-z]{0,1}(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/[a-z]{0,1}(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\(([COH0-9\-]*)\)\)$/ ) { ## RULE des M(IP)2C(16:1(1z..)/16:0(1z..)) -- Ex: M(IP)2C(d18:0/18:0(2OH))   OXYDES !!
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1, $2, $3, $4, $5, $6 ) ;
		}
		elsif ( $CommonName =~ /^(M\(IP\)2C)\([a-z]{0,1}(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\/[a-z]{0,1}(\d+):(\d+)[A-Z|a-z|0-9|,|\(\)]*\)$/ ) { ## RULE des M(IP)2C(16:1(1z..)/16:0(1z..)) -- Ex: M(IP)2C(t18:0/18:0)
			( $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ox ) = ( $1, $2, $3, $4, $5, undef ) ;
		}
		else {
			print "-->Cpd not parsed: ".$CommonName."\n" ;
		}
		
		## Set SimpleName : 
		$SimpleName  = &setSimpleName($CommonName, $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ch3_C, $Ch3_i, $Ox, $Post) ;
    }
    else {
    	croak "No Common name to get in method getSimpleNameFromCommonName!\n" ;
    }
    
    return($SimpleName) ;
}
### END of SUB

## Fonction : permet de reconstruire un nom simple a partir de donnees
## Input : $CommonName, $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ch3_C, $Ch3_i, $Ox, $Post
## Ouput : $SimpleName
sub setSimpleName {
    ## Retrieve Values
    
    my ( $CommonName, $Group, $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i, $Ch3_C, $Ch3_i, $Ox, $Post ) = @_;
    my ( $cTotal, $iTotal ) = ( undef, undef ) ;
    my $SimpleName = undef ;
    
    ### COMON NAME TO SIMPLE NAME !!
	if ( defined $Group ) {
		
		## SOMME DES CARBONES ET INSATURATIONS
		if ( ( defined $Ch1_C ) and ( defined $Ch1_i ) and ( defined $Ch2_C ) and ( defined $Ch2_i ) and ( defined $Ch3_C ) and ( defined $Ch3_i ) ) {
			$cTotal = ( $Ch1_C + $Ch2_C + $Ch3_C ) ;
			$iTotal = ( $Ch1_i + $Ch2_i + $Ch3_i ) ;
		}
		elsif ( ( defined $Ch1_C ) and ( defined $Ch1_i ) and ( defined $Ch2_C ) and ( defined $Ch2_i ) ) {
			$cTotal = ( $Ch1_C + $Ch2_C ) ;
			$iTotal = ( $Ch1_i + $Ch2_i ) ;
		}
		elsif ( ( defined $Ch1_C ) and ( defined $Ch1_i ) ) {
			$cTotal = ( $Ch1_C ) ;
			$iTotal = ( $Ch1_i ) ;
		}
		else {
			( $cTotal, $iTotal ) = ( undef, undef ) ;
		}
		## Composition du NOM
		if ( ( defined $cTotal ) and ( defined $iTotal ) ) {
			$SimpleName = $Group.'_'.$cTotal.':'.$iTotal ;
			
			## OXIDATION AND REST
			if ( defined $Ox ) { $SimpleName = $SimpleName.'('.$Ox.')' ; }
			if ( defined $Post ) { $SimpleName = $SimpleName.$Post ;	}
		}
		else { 	$SimpleName = $Group ; 			}
	}
	else { 	$SimpleName = $CommonName ; 	}
    
    return($SimpleName) ;
}
### END of SUB

## Fonction : permet de retourner une somme de features pour un common name
## Input : $CommonName de type LM
## Ouput : $Groupe, $Familly, $cTotal, $iTotal
sub getSimpleCommonName_Old {
    ## Retrieve Values
    my ( $CommonName ) = @_;
    my ($Groupe, $Familly, $cTotal, $iTotal, $Reste, $Ox ) = ( undef, undef, undef, undef, undef, undef, undef ) ;
    
    if ( $CommonName =~/([A-Za-z|0-9|\-]*)\((.*)\)$/ ) { #" Attention Common name conteint parfois des espaces en debut"
    	## retrieve $Familly and $Reste
    	( $Familly, $Reste, $Groupe) = ( $1, $2, '' ) ;
    	my ( $Ch1_C, $Ch2_C, $Ch1_i, $Ch2_i ) = ( 0, 0, 0, 0 ) ;
    	
    	## Gestion du "Groupe" et des carbones / insatures
		if ( $Reste =~/^([A-Z|a-z])\-(\d+):(\d+)[A-Z0-9,\(\)]*\/(\d+):(\d+)[A-Z0-9,\(\)]*/ ) { ## rule (X|x-16:1/16:1)
			$Groupe = $Familly.'-'.$1 ;
			( $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i )  = ( $2, $3, $4, $5 ) ;
		}
		elsif ( $Reste =~/^([A-Z|a-z])\-(\d+):(\d+)[A-Z0-9,\(\)]*\/([A-Z|a-z])\-(\d+):(\d+)[A-Z0-9,\(\)]*/ ) { ## rule (X|x-16:1/X|x-16:1)
			$Groupe = $Familly.'-'.$1.$4 ;
			( $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i )  = ( $2, $3, $5, $6 ) ;
		}
		elsif ( $Reste =~/^(\d+):(\d+)[A-Z0-9,\(\)]*\/([A-Z|a-z])\-(\d+):(\d+)[A-Z0-9,\(\)]*/ ) { ## rule (16:1/X|x-16:1)
			$Groupe = $Familly.'-'.$3 ;
			( $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i )  = ( $1, $2, $4, $5 ) ;
		}
#		elsif ( $Reste =~/(\d+):(\d+)[A-Z0-9,\(\)]*\/(\d+):(\d+)\([A-Z0-9,\(\)]*$/ ) { ## rule (16:1/16:1) 
		elsif ( $Reste =~/(\d+):(\d+)\/(\d+):(\d+)$/ ) { ## rule (16:1/16:1)
			$Groupe = $Familly ;
			( $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i )  = ( $1, $2, $3, $4 ) ;
		}
		elsif ( $Reste =~/^([A-Z|a-z])(\d+):(\d+)[A-Z0-9,\(\)]*\/(\d+):(\d+)[A-Z0-9,\(\)]*/ ) { ## rule (X|x16:1/16:1) 
			$Groupe = $Familly.'-'.$1 ; ;
			( $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i )  = ( $2, $3, $4, $5 ) ;
		}
		elsif ( $Reste =~/^(\d+):(\d+)[A-Z0-9,\(\)]*\/([A-Z|a-z])(\d+):(\d+)[A-Z0-9,\(\)]*/ ) { ## rule (16:1/X|x16:1)
			$Groupe = $Familly.'-'.$3 ;
			( $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i )  = ( $1, $2, $4, $5 ) ;
		}
		elsif ( $Reste =~/^([A-Z|a-z])(\d+):(\d+)[A-Z0-9,\(\)]*\/([A-Z|a-z])(\d+):(\d+)[A-Z0-9,\(\)]*/ ) { ## rule (X|x16:1/X|x16:1)
			$Groupe = $Familly.'-'.$1.$4 ;
			( $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i )  = ( $2, $3, $5, $6 ) ;
		}
		## Cas des Oxydes ([320])
		elsif ( $Reste =~/^(\d+):(\d+)[A-Z0-9,\(\)]*\/(\d+):(\d+)[A-Z0-9,\(\)]*\(([A-Z|a-z|0-9|\[\]]*)\)/ ) { ## rule (16:1/16:1)(xOH[S]) 
			$Groupe = $Familly.'-'.$1 ;
			
			$Ox = $5 ; ## for Ox gpt
			print "$Ox\n\n" ;
			( $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i )  = ( $1, $2, $3, $4 ) ;
		}
		else {
			carp "This reste ($Reste) is unknown in actual parsing rules\n" ;
			$Groupe = $CommonName ;
			( $Ch1_C, $Ch1_i, $Ch2_C, $Ch2_i )  = ( 0, 0, 0, 0 ) ;
		}
		
		
		
		## End of parsing "Gestion du "Groupe" et des carbones / insatures"
		
		## Sum Carbones and insaturates
    	if ( ( defined $Ch1_C ) and ( defined $Ch1_i ) and ( defined $Ch2_C ) and ( defined $Ch2_i ) ) {
    		if ( ( $Ch1_C+$Ch2_C ) < ( $Ch1_i+$Ch2_i ) ) {
    			warn "Number of insatured are greater than carbon for $CommonName \n" ;
    		}
    		else {
    			$cTotal = $Ch1_C + $Ch2_C ;
    			$iTotal = $Ch1_i + $Ch2_i ;
    		}
    	}
    	else {
    		croak "Carbones or insatures number is not defined \n" ;
    	}
    } # End IF
    elsif ( $CommonName =~/^-$/ ) { ## cas du no common name dans la base (-)
    	$Groupe = 'UnNAMED_IN_LM' ;
    	$cTotal = 0 ;
    	$iTotal = 0 ;
    } # End ELSIF
    else {
		print "Not yet parsing rules for this commonName $CommonName\n" ;
		$Groupe = $CommonName ;
    	$cTotal = 0 ;
    	$iTotal = 0 ;
	}
    
    return( $Groupe, $Familly, $cTotal, $iTotal, $Ox ) ;
}
### END of SUB

## Fonction : permet de regrouper les composes ayant le meme commona name simplifie
## Input : 
## Ouput :
sub clusteringCommonName {
    ## Retrieve Values
    my ( $refH_Features ) = @_;
    my %Results = %{$refH_Features} ;
    my %Clusters = () ;
    
#    print Dumper %Results ;
    
    foreach my $id ( keys %Results ) {
    	
    	if ( $id ne 'nbentries' ) {
    		
	    	my $oldFormula = '' ;
			my $Cpd = undef ;
			
			if (defined $Results{$id}{'simplename'}) { 	$Cpd = $Results{$id}{'simplename'} ;  }
#			else {		 								print"+++COCO\n"; $Cpd =  'UNDEF' ; 	} ## ?? comprends pas l'impact sur la suite !
			
			
			if (  !defined $Clusters{$Cpd}{'list'} ) { $Clusters{$Cpd}{'list'} = [] ; 	}		
			
			my $currentFormula = $Results{$id}{'formula'} ;
			
			if ( $currentFormula ne $oldFormula ) {
				$Clusters{$Cpd}{'formula'} = $Results{$id}{'formula'} ;
				push ( @{$Clusters{$Cpd}{'list'} }, $id ) ;
			}
			else {
				push ( @{$Clusters{$Cpd}{'list'} }, $id ) ;
				next ;
			}
    	}
    	else { # Gere le cas ou la key du hash courant est le nombre d'entrees...
    		next ;
    	}
    }
    return(\%Clusters) ;
}
### END of SUB





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