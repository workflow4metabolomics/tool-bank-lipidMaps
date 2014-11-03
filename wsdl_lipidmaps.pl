#! perl

use strict ;
no strict "refs" ;
use warnings ;
use Carp qw (cluck croak carp confess) ;
use Exporter ;
use diagnostics ;

use Data::Dumper ;
use POSIX ;
use XML::Twig;
use Getopt::Long ;


## Permet de localisez le repertoire du script perl d'origine
use FindBin;
## permet de definir la localisation des .pm et .conf
use lib $FindBin::Bin ;
#my $libPath = $FindBin::Bin."/lib";
my $binPath = $FindBin::Bin ;

## dedicated lib

use lib::lipidmaps ;
use lib::parser ;
use lib::writer ;
# more inra lib
use lib::conf  qw( :ALL ) ;
use lib::csv  qw( :ALL ) ;
use lib::operations  qw( :ALL ) ;

## Initialized values
#
my ( $help, $input_file, $line_header, $col_mass, $col_rt, $decimal, $round_type, $delta ) = ( undef, undef, undef, undef, undef, undef, undef, undef ) ; 
my ( $list_oxidation, $list_neutral_loss ) = ( undef, undef, undef ) ; 
my ( $col_classif_id, $selected_cat, $selected_cl, $selected_subcl ) = ( undef, undef, undef, undef ) ; 
my ( $output_csv_file, $output_html_file, $output_link_file  ) = ( undef, undef, undef ) ;

# for test ONLY !
#( $input_file, $line_header, $col_mass, $col_rt, $decimal, $round_type, $delta )  = ('E:\\TESTs\\galaxy\\lipidmaps\\test_lipidmaps_avec_class_short.csv', 1, 2, 3, 2, 'round', 0.5 ) ;
#( $list_oxidation, $list_neutral_loss ) = ( 'loss_O,loss_2O,NA', 'loss_hydroperoxide,loss_water' ) ;
#( $list_oxidation, $list_neutral_loss ) = ( 'NA','NA,loss_hydroperoxide,loss_water' ) ;
#( $selected_cat, $selected_cl, $selected_subcl ) = ( 3, 301, 30103 ) ;
#( $selected_cat, $selected_cl, $selected_subcl ) = ( 3, 'NA_3', 'NA_301' ) ;
#( $col_classif_id ) = 4 ;
#( $output_html_file ) = ('E:\\TESTs\\galaxy\\lm.html') ;
#( $output_csv_file ) = ('E:\\TESTs\\galaxy\\lm.csv') ;

&GetOptions ( 	"help|h"     		=> \$help,       		# HELP
				"input|i:s"			=> \$input_file,		# path for input file (CSV format) -- Mandatory
				"lineheader:i"		=> \$line_header, 		## header presence in tabular file
				"colmass:i"			=> \$col_mass,			# Input file Column containing Masses for query -- Mandatory
				"colrt:i"			=> \$col_rt,			# Input file Column containing Retention time
				"decimal:i"			=> \$decimal	,		# Significante decimal on mass -- Mandatory
				"listoxidation:s"	=> \$list_oxidation,	## option : liste des atomes a gerer sur les masses experimentales
				"listneutralloss:s"	=> \$list_neutral_loss,	## option : liste des atomes a gerer sur les masses experimentales
				"round:s" 			=> \$round_type,		# Type of truncation -- Mandatory
				"delta:f" 			=> \$delta,				# delta of mass -- Mandatory
				"cat:i" 			=> \$selected_cat,		# Number corresponding to the main category in LIPIDMAPS -- Optional
				"class:i"			=> \$selected_cl,		# Number corresponding to the main classe in LIPIDMAPS -- Optional
				"subclass:i"		=> \$selected_subcl,	# Number corresponding to the sub class in LIPIDMAPS -- Optional
				"output:s"			=> \$output_csv_file,	# File+Path for the results (CVS) -- Mandatory
				"view:s"			=> \$output_html_file,	# File+Path for the view results (HTML) -- Mandatory
				"colclassif:i"		=> \$col_classif_id,	# Input file Column containing LM classes ID for query -- Optional
            ) ;

#=============================================================================
#                                EXCEPTIONS
#=============================================================================
$help and &help ;

## CMD LINE IN GALAXY :
#wsdl_lipidmaps.pl -input $file_input -colmass $col_mass -colrt $col_rt -decimal $decimal -round $round_type -delta $tolerance
##if $query_type.complex_query_action=="no" :
#	-cat $query_type.select_cat.filter_cat -class $query_type.select_cat.select_class.filter_class -subclass $query_type.select_cat.select_class.select_subclass.filter_subclass
#	#if data_type.modify_data_action=="yes" :
#		-listneutralloss $neutral_loss -listoxidation $oxidation
#	#end if
##else :
#	#if data_type.modify_data_action=="yes" :
#	 -colclassif $query_type.col_classif_id -listneutralloss $neutral_loss -listoxidation $oxidation
#	#end if
##end if
#-output $output_result -view $output_view

## --------------- Global parameters ---------------- :
my $nb_pages_for_html_out = 1 ;

## Conf file
my ( $CONF, %RULES, %RECIPES, %TRANSFO ) = ( undef, (), (), ()  ) ;
foreach my $conf ( <$binPath/*.conf> ) {
	my $oConf = lib::conf::new() ;
	$CONF = $oConf->as_conf($conf) ;
}

## work with it :
## get RULES lists :
foreach (keys (%$CONF)) {
	if( $_ =~/^RULE/ ) { $RULES{$_} = $CONF->{$_} ; 	} ## rules for clustering
	elsif( $_ =~/^RECIPE/ ) { $RECIPES{$_} = $CONF->{$_} ; 	} ## fields retrieved with each rule
	elsif( $_ =~/^ANNOT/ ) { $TRANSFO{$_} = $CONF->{$_} ; 	} ## Transformation annotation in output files
}

## Init var
my ( $init_csv_rows, $init_mzs, $init_rts, $classif_ids, $round_init_mzs ) = ( undef, undef, undef, undef, undef ) ;
my ( @ox_or_loss_names, @ox_or_loss_values, @transfo_init_mzs, @transfo_annotations, @transfo_init_mz_queries, @transfo_init_mz_results, @entries_results, @clusters_results, @entries_total_nb ) = ( (), (), (), (), (), (), (), (), ()  ) ;
my ( $ox_names, $ox_values, $loss_names, $loss_values ) = ( [], [], [], [] ) ;
my ( $is_header, $tbody_object) = (undef, undef) ;


#print "-----------**********MAIN -- DUMP*********-------------\n" ;

#### --------------------------------- 01 :: Prepare all and Parsing steps on inputs -------------------------------------

## Open CVS FILE / Extract and transform Masses  
if ( ( defined $input_file ) and ( -e $input_file ) ) {
	
	## parse all csv for later : output csv build
	my $ocsv_input  = lib::csv->new() ;
	my $csv = $ocsv_input->get_csv_object( "\t" ) ;
	$init_csv_rows = $ocsv_input->parse_csv_object($csv, \$input_file) ;
	
	
	if ( ( defined $line_header ) and ( $line_header > 0 ) ) { $is_header = 'yes' ;	}
	
	## parse masses
	if ( defined $col_mass ) {
		my $ocsv = lib::csv->new() ;
		my $csv = $ocsv->get_csv_object( "\t" ) ;
		$init_mzs = $ocsv->get_value_from_csv( $csv, $input_file, $col_mass, $is_header ) ; ## retrieve mz values on csv
		$init_rts = $ocsv->get_value_from_csv( $csv, $input_file, $col_rt, $is_header ) ; ## retrieve rt values on csv
	}
	## round masses
	if ( ( defined $round_type ) and ( defined $decimal ) ) {
		my $oround = lib::operations::new() ;
		if 		( $round_type eq 'truncation' ) { 	$round_init_mzs = $oround->truncate_nums( $init_mzs, $decimal ) ; 			}
		elsif 	( $round_type eq 'round' ) {		$round_init_mzs = $oround->round_nums( $init_mzs, $decimal ) ;  			}
		else {										croak "The selected option for data transformation is unknown !\n" ; 	}
	}
	## parse classif ids -- optionnal
	if ( defined $col_classif_id ) {
		my $ocsv = lib::csv::new() ;
		my $csv = $ocsv->get_csv_object( "\t" ) ;
		$classif_ids = $ocsv->get_value_from_csv( $csv, $input_file, $col_classif_id, $is_header ) ;
	}
	
	## Uses N mz and theirs entries per page (see config file).
	# how many pages you need with your input mz list?
	$nb_pages_for_html_out = ceil( scalar(@{$init_mzs} ) / $CONF->{HTML_ENTRIES_PER_PAGE} )  ;
	
}
else {
	croak "Can't find any input file $input_file\n" ;
}

#### ------------------- 02 :: optionnal work on masses with neutral loss and/or oxydation == modif : -------------------

# get and merge ox and neutral loss envt :
my $oparser = lib::parser::new() ;
if ( ( defined $list_oxidation ) and ( defined $CONF )  ) 		{ ( $ox_names, $ox_values ) = $oparser->get_oxidation_ref( $CONF, $list_oxidation ) ; }
if ( @{$ox_values} ) 	{ 	push( @ox_or_loss_values, @{$ox_values} ) ;  push( @ox_or_loss_names, @{$ox_names} ) ; }
if ( ( defined $list_neutral_loss ) and ( defined $CONF )  ) 	{ ( $loss_names, $loss_values ) = $oparser->get_neutral_loss_ref( $CONF, $list_neutral_loss ) ; }
if ( @{$loss_values} ) 	{ 	push( @ox_or_loss_values, @{$loss_values} ) ;  push( @ox_or_loss_names, @{$loss_names} ) ; }

# prepare a list of masses indpt of modif (ox/neutral loss) presence.
my $init_mz_index = 0 ;
foreach my $init_mz (@{$round_init_mzs}) {
	
	my @transfo_values_list = () ;
	my @transfo_name_list = () ;
	my $init_annot = 'Init_MZ' ;
	
	push ( @transfo_values_list, \$init_mz ) ; ## the submitted init mass
		## work on values
	if ( @ox_or_loss_values ) {
		my $oround = lib::operations::new() ;
		my $round_transfo_mzs = $oround->round_nums( \@ox_or_loss_values, $decimal ) ; ## We choose to around the number.
		foreach my $transfo_mz ( @{$round_transfo_mzs} ) {
			my $osub = lib::operations::new() ;
			my $transfo_init_mz = $osub->subtract_num( $init_mz, $transfo_mz ) ;
			push ( @transfo_values_list, $transfo_init_mz ) ;
		}
	}
	
	## work on annotation for output
	push ( @transfo_name_list, \$init_annot) ; ## init annot
	if ( @ox_or_loss_names ) {
		foreach my $ox_or_loss_name (@ox_or_loss_names) {
			if ( $TRANSFO{'ANNOT_'.$ox_or_loss_name} ) { 
				my $transfo = $TRANSFO{'ANNOT_'.$ox_or_loss_name} ;
				push ( @transfo_name_list, \$transfo ) ; }
		}
	}
	
	## push final arrays
	push ( @transfo_init_mzs, \@transfo_values_list ) ;
	push ( @transfo_annotations, \@transfo_name_list ) ;
	
	## foreach transfo mass (round and/or modif)
	my $i = 0 ;
	my ( @queries, @query_results, @query_result_entries, @query_result_entry_nbs, @query_result_clusters ) = ( (), (), (), (), () ) ;
	
	foreach my $transfo_mz ( @{$transfo_init_mzs[$init_mz_index]} ) {
		## LM recommandation : If you write a script to automate calls to LMSD, 
		# please be kind and do not hit our server more often than once per 20 seconds.
		# We may have to kill scripts that hit our server more frequently.
		sleep (20) ; 
		my ( $cat, $cl, $subcl ) = ( undef, undef, undef ) ;
	#	if ( $i >= ( scalar( @transfos_values )-1 ) ) { $i = 0 ; } ## manage the modif for each masses.
			
		## get the classif level :
		if ( defined $classif_ids ) {
			if ( $classif_ids->[$i] ) {
				my $olevel = lib::parser::new() ;
				$cat = $olevel->set_category( $classif_ids->[$i] ) ;
				$cl = $olevel->set_class( $classif_ids->[$i] ) ;
				$subcl = $olevel->set_subclass( $classif_ids->[$i] ) ;
				( $cat, $cl, $subcl ) = ( $$cat, $$cl, $$subcl ) ;
			}
			else { croak "This information is not available in your parsing ids\n" ; }
		}
		else {
			if ( ( defined $selected_subcl) or ( defined $selected_cl ) or ( defined $selected_cat ) ) {
				if ( ( $selected_cat !~ /^NA(.*)/ ) ) { ( $cat ) = ( $selected_cat ) ; }
				if ( ( $selected_cl !~ /^NA(.*)/ ) ) { ( $cl ) = ( $selected_cl ) ; }
				if ( ( $selected_subcl !~ /^NA(.*)/ ) ) { ( $subcl ) = ( $selected_subcl ) ; }
			}
			else { croak "No selected category or classification ids list\n" ; }
		}
		
		## buid and get http query :
		my $oquery = lib::lipidmaps::new() ;
		my $ref_http_query = $oquery->build_lm_mass_query( $CONF->{'SEARCH_URL'}, $delta, $cat, $cl, $subcl ) ; ## build the query for LM WS, return a list of http, get method
		
		## set entries clusters
		my ( $http_result_mz, $http_query_mz ) = $oquery->get_lm_mass_query($ref_http_query, $transfo_mz) ; ## execute the query, return a list of non-splited lm_entries.
		my ( $mz_entries_results, $mz_entries_nb, $mz_clusters_results ) = ( undef, undef, undef ) ;
		if ( $$http_result_mz ne '' ) { # avoid empty LM results
			( $mz_entries_results, $mz_entries_nb ) = $oquery->get_lm_entry_object($http_result_mz, $transfo_mz) ; ## get all features of each entry and return a list of features keept in a hash
			$mz_clusters_results = $oquery->get_cluster_object($mz_entries_results, \%RULES, \%RECIPES) ; ## clustering all entries and return a list of clusters keept in a hash
		}
		else { # manage empty LM results
			( $mz_entries_results, $mz_entries_nb, $mz_clusters_results ) = ( [], \0, [] ) ;
		}	
		
		push( @queries, $http_query_mz ) ;
		push( @query_results, $http_result_mz ) ;
		push( @query_result_entries, $mz_entries_results ) ;
		push( @query_result_entry_nbs, $mz_entries_nb ) ;
		push( @query_result_clusters, $mz_clusters_results ) ;
	} ## end foreach transfo_mz
	
	$i++ ; # implem the mz rank	
	push( @transfo_init_mz_queries, \@queries ) ;
	push( @transfo_init_mz_results, \@query_results ) ;
	push( @entries_results, \@query_result_entries ) ;
	push( @entries_total_nb, \@query_result_entry_nbs ) ;
	push( @clusters_results, \@query_result_clusters ) ;
	
	$init_mz_index++ ;
} ## end foreach init_mz


#### -------------------------------- 05 :: Writes LM results --------------------------------------------

# prepare data and write html output :
if ( defined $output_html_file) {
	my $ohtml = lib::writer->new() ;
	$tbody_object = $ohtml->set_html_tbody_object( $nb_pages_for_html_out, $CONF->{HTML_ENTRIES_PER_PAGE} ) ;
	$tbody_object = $ohtml->add_mz_to_tbody_object( $tbody_object, $CONF->{HTML_ENTRIES_PER_PAGE}, $init_mzs, $init_rts, \@entries_total_nb) ;
	$tbody_object = $ohtml->add_transformation_to_tbody_object( $init_mzs, \@transfo_init_mzs, \@transfo_annotations, $tbody_object ) ;
	$tbody_object = $ohtml->add_cluster_to_tbody_object( $init_mzs, \@transfo_init_mzs, \@clusters_results, $tbody_object ) ;
	$tbody_object = $ohtml->add_entry_to_tbody_object( $init_mzs, \@transfo_init_mzs, \@clusters_results, \@entries_results, $tbody_object ) ;	
	my $output_html = $ohtml->write_html_skel(\$output_html_file, $tbody_object, $nb_pages_for_html_out, $CONF->{'HTML_TEMPLATE'}, $CONF->{'JS_GALAXY_PATH'}, $CONF->{'CSS_GALAXY_PATH'}) ;
}


#write csv ouput : add 'lipidmaps' column to input file
my $lm_matrix = undef ;
my $ocsv = lib::writer->new() ;
if ( defined $is_header ) { $lm_matrix = $ocsv->set_lm_matrix_object('lipidmaps', $init_mzs, \@transfo_annotations, \@clusters_results ) ;	}
else { $lm_matrix = $ocsv->set_lm_matrix_object( undef, $init_mzs, \@transfo_annotations, \@clusters_results ) ;	}

$lm_matrix = $ocsv->add_lm_matrix_to_input_matrix($init_csv_rows, $lm_matrix) ;
$ocsv->write_csv_skel(\$output_csv_file, $lm_matrix) ;



#print "-----------**********RETURNS*********-------------\n" ;
#print "\n----- Init Input Data in CSV -----\n" ;
#print Dumper $init_csv_rows ;
#print "\n---- Init masses parsed ...\n" ;
#print Dumper $init_mzs ;
#print "\n---- Init rts parsed ...\n" ;
#print Dumper $init_rts ;
#print "\n---- Init masses arounded ...\n" ;
#print Dumper $round_init_mzs ;
#print "\n---- Ox ...\n" ;
#print Dumper $ox_names ;
#print Dumper $ox_values ;
#print "\n---- Neutral loss ...\n" ;
#print Dumper $loss_names ;
#print Dumper $loss_values ;
#print "\n---- Applied transformations ('\@ox_or_loss_values') ...\n" ;
#print Dumper @ox_or_loss_values ;
#print "\n---- Masses modif ('\@transfo_init_mzs') ...\n" ;
#print Dumper @transfo_init_mzs ;
#print "\n---- Transfo annotation ('\@transfo_annotations') ...\n" ;
#print Dumper @transfo_annotations ;
#print "\n---- Queries ('\@transfo_init_mz_queries')...\n" ;
#print Dumper @transfo_init_mz_queries ;
#print "\n---- WS Results ('@transfo_init_mz_results')...\n" ;
#print Dumper @transfo_init_mz_results ;
#print "\n---- Entries results ('\@entries_results')...\n" ;
#print Dumper @entries_results ;
#print "\n---- Entries results numbers ('\@entries_total_nb')...\n" ;
#print Dumper @entries_total_nb ;
#print "\n---- Clusters results ('\@clusters_results')...\n" ;
#print Dumper @clusters_results ;
#print "\n---- Data model filed...\n" ;
#print "...with csv->\n" ;
#print Dumper $lm_matrix ;
#print "...with html->\n" ;
#print Dumper $tbody_object ;


#====================================================================================
# Help subroutine called with -h option
# number of arguments : 0
# Argument(s)        :
# Return           : 1
#====================================================================================
sub help {
    print STDERR "
    	
	# wsdl_lipidmaps
	# Input : 
	# Author : Franck GIACOMONI and Marion LANDI
	# Email : fgiacomoni\@clermont.inra.fr
	# Version : 1.0
	# Created : 16/07/2012
	USAGE :
	        wsdl_lipidmaps.pl -help
	        wsdl_lipidmaps.pl 
	        	-input \$file_input -colmass \$col_mass -colrt \$col_rt -decimal \$decimal -round \$round_type -delta \$tolerance
	        	-output \$output_result -view \$output_view
	        	-cat -class -subclass OR -colclassif
				-listneutralloss \$neutral_loss -listoxidation \$oxidation [optionnal]
	";
}


