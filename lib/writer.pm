package lib::writer ;

use strict;
use warnings;

use Data::Dumper;
use Carp ;
use HTML::Template ;

#use lib::csv  qw( :ALL ) ;

use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = "1.0";
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(write_csv_skel write_html_skel );
%EXPORT_TAGS = ( ALL => [qw( write_csv_skel write_html_skel)] );

=head1 NAME

My::Module - An example module

=head1 SYNOPSIS

    use My::Module;
    my $object = My::Module->new();
    print $object->as_string;

=head1 DESCRIPTION

This module does not really exist, it
was made for the sole purpose of
demonstrating how POD works.

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

=head2 METHOD write_csv_skel

	## Description : prepare and write csv output file
	## Input : $csv_file, $rows
	## Output : $csv_file
	## Usage : my ( $csv_file ) = write_csv_skel( $csv_file, $rows ) ;
	
=cut
## START of SUB
sub write_csv_skel {
	## Retrieve Values
    my $self = shift ;
    my ( $csv_file, $rows ) = @_ ;
    
    my $ocsv = lib::csv::new() ;
	my $csv = $ocsv->get_csv_object("\t") ;
	$ocsv->write_csv_from_arrays($csv, $$csv_file, $rows) ;
    
    return($csv_file) ;
}
## END of SUB

=head2 METHOD set_lm_matrix_object

	## Description : build the lm_row under its ref form
	## Input : $init_mzs, $transfo_results, $cluster_results
	## Output : $lm_matrix
	## Usage : my ( $lm_matrix ) = set_lm_matrix_object( $init_mzs, $transfo_results, $cluster_results ) ;
	
=cut
## START of SUB
sub set_lm_matrix_object {
	## Retrieve Values
    my $self = shift ;
    my ( $header, $init_mzs, $transfo_annot, $cluster_results ) = @_ ;
    
    my @lm_matrix = () ;    
    
    if ( defined $header ) {
    	my @headers = () ;
    	push @headers, $header ;
    	push @lm_matrix, \@headers ;
    }
    
    my $index_mz = 0 ;
    foreach my $mz ( @{$init_mzs} ) {
    	my @clusters = () ;
    	my $cluster_col = undef ;
    	my $index_annot = 0 ;
    	my @clusters_tmp = () ;
    	    	
    	foreach my $annot ( @{$transfo_annot->[$index_mz]} ) {
    		my $transfo = $$annot ;
    		if ($transfo eq 'Init_MZ') { $transfo = '' ;  }
    		my $index_cluster = 0 ;
    		
    		if ($cluster_results->[$index_mz][$index_annot]) {
    			
    			foreach my $cluster ( @{$cluster_results->[$index_mz][$index_annot]} ) {
    				
	    			my $delta = $cluster->{CLUSTER_DELTA} ;
	    			my $name = $cluster->{CLUSTER_NAME} ;
	    			my $formula = $cluster->{FORMULA} ;
	    			my $lm_id_ex = $cluster->{ENTRY_IDS}[0] ;
	    			
	    			## METLIN data display model 
	    			## entry1=VAR1::VAR2::VAR3::VAR4|entry2=VAR1::VAR2::VAR3::VAR4|...
	    			## Format : -0.18::(PI_22:0)::(C31H61O12P)::LMGP06050024
	    			##(score::name::mz::formula::adduct::id)
	    			push (@clusters_tmp, $$delta.'::('.$$name.')'.$transfo.'::('.$$formula.')'.$transfo.'::'.$$lm_id_ex) ;
	    			  			
	    			$index_cluster++ ;
	    		}  ## end FOR cluster
    		} ## end IF    		
    		$index_annot++ ;
    	} ## end FOR transfo
    	
    	my $nb_total_cluster = scalar(@clusters_tmp) ;
    	my $index_pipe = 0 ;
    	
    	## Sort the cluster by score (start of the string)
    	my @sorted_clusters_tmp = sort { lc($a) cmp lc($b) } @clusters_tmp ;
    	
    	foreach (@sorted_clusters_tmp) {
    		if ($index_pipe < $nb_total_cluster-1 ) { $cluster_col .= $_.'|' ; }
    		else { $cluster_col .= $_ ; }
    		$index_pipe++ ;
    	}
    	
    	if ( !defined $cluster_col ) { $cluster_col = 'No_result_found_on LMDS' ; }
    	push (@clusters, $cluster_col) ;
    	push (@lm_matrix, \@clusters) ;
    	$index_mz++ ;
    }  ## end FOR mz
    return(\@lm_matrix) ;
}
## END of SUB

=head2 METHOD add_lm_matrix_to_input_matrix

	## Description : build a full matrix (input + lm column)
	## Input : $input_matrix_object, $lm_matrix_object
	## Output : $output_matrix_object
	## Usage : my ( $output_matrix_object ) = add_lm_matrix_to_input_matrix( $input_matrix_object, $lm_matrix_object ) ;
	
=cut
## START of SUB
sub add_lm_matrix_to_input_matrix {
	## Retrieve Values
    my $self = shift ;
    my ( $input_matrix_object, $lm_matrix_object ) = @_ ;
    
    my @output_matrix_object = () ;
    my $index_row = 0 ;
    
    foreach my $row ( @{$input_matrix_object} ) {
    	my @init_row = @{$row} ;
    	
    	if ( $lm_matrix_object->[$index_row] ) {
    		my $dim = scalar(@{$lm_matrix_object->[$index_row]}) ;
    		
    		if ($dim > 1) { warn "the add method can't manage more than one column\n" ;}
    		my $lm_col =  $lm_matrix_object->[$index_row][$dim-1] ;

   		 	push (@init_row, $lm_col) ;
	    	$index_row++ ;
    	}
    	push (@output_matrix_object, \@init_row) ;
    }
    return(\@output_matrix_object) ;
}
## END of SUB

=head2 METHOD write_html_skel

	## Description : prepare and write the html output file
	## Input : $html_file_name, $html_object, $html_template
	## Output : $html_file_name
	## Usage : my ( $html_file_name ) = write_html_skel( $html_file_name, $html_object ) ;
	
=cut
## START of SUB
sub write_html_skel {
	## Retrieve Values
    my $self = shift ;
    my ( $html_file_name,  $html_object, $pages, $html_template, $js_path, $css_path ) = @_ ;
    
    my $html_file = $$html_file_name ;
    
    if ( defined $html_file ) {
		open ( HTML, ">$html_file" ) or die "Can't create the output file $html_file " ;
		
		if (-e $html_template) {
			my $ohtml = HTML::Template->new(filename => $html_template);
			if ( (defined $js_path) and (defined $css_path) ) { $ohtml->param(  CSS_GALAXY_PATH => $css_path, JS_GALAXY_PATH => $js_path ) ; }
			$ohtml->param(  PAGES_NB => $pages  ) ;
			$ohtml->param(  PAGES => $html_object  );
			print HTML $ohtml->output ;
		}
		else {
			croak "Can't fill any html output : No template available ($html_template)\n" ;
		}
		
		close (HTML) ;
    }
    else {
    	croak "No output file name available to write HTML file\n" ;
    }
    return(\$html_file) ;
}
## END of SUB

=head2 METHOD set_html_tbody_object

	## Description : initializes and build the tbody object (perl array) need to html template
	## Input : $nb_pages, $nb_items_per_page
	## Output : $tbody_object
	## Usage : my ( $tbody_object ) = set_html_tbody_object($nb_pages, $nb_items_per_page) ;
	
=cut
## START of SUB
sub set_html_tbody_object {
	my $self = shift ;
    my ( $nb_pages ) = @_ ;

	my ( @tbody_object ) = ( ) ;
	
	for ( my $i = 1 ; $i <= $nb_pages ; $i++ ) {
	    
	    my %pages = ( 
	    	# tbody feature
	    	PAGE_NB => $i,
	    	MASSES => [], ## end MASSES
	    ) ; ## end TBODY N
	    push (@tbody_object, \%pages) ;
	}
    return(\@tbody_object) ;
}
## END of SUB

=head2 METHOD add_mz_to_tbody_object

	## Description : initializes and build the mass object (perl array) need to html template
	## Input : $init_masses, $nb_results
	## Output : $mz_objects
	## Usage : my ( $mz_object ) = add_mz_to_tbody_object($init_masses, $rts, $nb_results) ;
	
=cut
## START of SUB
sub add_mz_to_tbody_object {
	## Retrieve Values
    my $self = shift ;
    my ( $tbody_object, $nb_items_per_page, $init_masses, $nb_total_results ) = @_ ;
	my @colors = ('white', 'green') ;
	my ( $current_page, $mz_index, $icolor, $total_entries ) = ( 0, 0, 0, 0 ) ;
	
	foreach my $page ( @{$tbody_object} ) {
		
		my @colors = ('white', 'green') ;
		my ( $current_index, , $icolor ) = ( 0, 0 ) ;
		
		for ( my $i = 1 ; $i <= $nb_items_per_page ; $i++ ) {
			# 
			if ( $current_index > $nb_items_per_page ) { ## manage exact mz per html page
				$current_index = 0 ; 
				last ; ##
			}
			else {
				
				if ( exists $init_masses->[$mz_index]  ) {

					## calcul total entries
					my @total = @{$nb_total_results->[$mz_index]} ;
					foreach my $nb ( @total ) { $total_entries += $$nb ; }
					
					if ($total_entries > 0) {
						$current_index++ ;
						if ( $icolor > 1 ) { $icolor = 0 ; }
						
						my %mz = (
							# mass feature
#							MASS => $init_masses->[$mz_index], RT => $rts->[$mz_index], TOTAL => $total_entries,
							MASS => $init_masses->[$mz_index], TOTAL => $total_entries,
							# html attr for mass
							COLOR => ($colors[$icolor]), NB_MASS => $mz_index+1, NB_CLUSTER_BY_MASS => 0, NB_ENTRY_BY_MASS => 0,
							# cluster group
							TRANSFORMS => [], ## end TRANSFOS
						) ; ## end mass N
						
						## Html attr for mass
						$icolor++ ;
						push ( @{ $tbody_object->[$current_page]{MASSES} }, \%mz ) ;
					}
					else {
						## Can't fill the object
						$i-- ;
					}
					$mz_index++ ;
					$total_entries = 0 ;
				}
			}
		}
		$current_page++ ;
	}

    return($tbody_object) ;
}
## END of SUB

=head2 METHOD add_transformation_to_tbody_object

	## Description : initializes and builds the transfo mass object (perl array)
	## Input : $init_masses, $transfo_masses, $transfo_names, $mz_objects
	## Output : $transfo_objects
	## Usage : my ( $transfo_objects ) = add_transformation_to_tbody_object( $init_masses, $transfo_masses, $transfo_names, $mz_objects ) ;
	
=cut
## START of SUB
sub add_transformation_to_tbody_object {
	## Retrieve Values
    my $self = shift ;
    my ( $transfo_masses, $transfo_annot, $tbody_object ) = @_ ;
    
    my $index_page = 0 ;
    
    foreach my $page (@{$tbody_object}) {
    	
    	my $index_mz = 0 ;
    		
		foreach my $init_filtered_mz ( @{ $tbody_object->[$index_page]{MASSES} }) {

	    	my $index_transfo = 0 ;
	    	my $index_filtered_mz = undef ;
	    	
	    	if ($init_filtered_mz->{NB_MASS} ) {
	    		$index_filtered_mz = $init_filtered_mz->{NB_MASS}-1 ;
	    	}
	    	else{
	    		last;
	    	}
	    	
	    	foreach my $transfo ( @{$transfo_masses->[$index_filtered_mz]} ) {
	    		
	    		my $transfo_type = $transfo_annot->[$index_filtered_mz][$index_transfo] ;
	    		my $color = undef ;
	    		# manage Bolt color : 
	    		if ($tbody_object->[$index_page]{MASSES}[$index_mz]{COLOR} eq 'white') {
	    			$color = 'grey-bolt' ;
	    		}
	    		else {
	    			$color = 'green-bolt' ;
	    		}
	    		
		        my %transformation = (
		        	# html attr for transformation
		        	COLOR => $color,
					# Transfo features
					TRANSFO_TYPE => $$transfo_type,
					# cluster group
					CLUSTERS => [], 
		        ) ;
		        
				push(@{$tbody_object->[$index_page]{MASSES}[$index_mz]{TRANSFORMS}}, \%transformation ) ;
	        	$index_transfo++ ;
	    	}
	    	$index_mz ++ ;
	    }
    	$index_page++ ;
    }

    return($tbody_object) ;
}
## END of SUB

=head2 METHOD add_cluster_to_tbody_object

	## Description : initializes and builds the cluster object (perl array)
	## Input : $init_masses, $transfo_masses, $clusters_results, $mz_objects
	## Output : $mz_objects
	## Usage : my ( $cluster_objects ) = add_cluster_to_tbody_object($init_masses, $transfo_masses, $clusters_results, $mz_objects) ;
	
=cut
## START of SUB
sub add_cluster_to_tbody_object {
	## Retrieve Values
    my $self = shift ;
    my ( $transfo_masses, $clusters_results, $tbody_object ) = @_ ;
    my @cluster_objects = () ;
    
    my $index_page = 0 ;
    my $current_mz = 0 ; 
    
#    print Dumper  $transfo_masses;
    
#    print Dumper $clusters_results ;
    
    foreach my $page (@{$tbody_object}) {
    	
    	my $index_mz = 0 ;

		foreach my $filtered_mz  ( @{ $tbody_object->[$index_page]{MASSES} }) {
			
			my $index_filtered_mz = undef ;
	    	
	    	if ($filtered_mz->{NB_MASS} ) {
	    		$index_filtered_mz = $filtered_mz->{NB_MASS}-1 ;
	    	}
	    	else{
	    		last;
	    	}
			
			my $index_transfo = 0 ;
			
			foreach my $transfo ( @{$transfo_masses->[$index_filtered_mz]} ) {
				
				my $index_cluster = 0 ;
				
				foreach my $cluster (@{$clusters_results->[$index_filtered_mz][$index_transfo]}) {
					
					my $cluster_formula = $cluster->{FORMULA} ;
		    		my $cluster_name = $cluster->{CLUSTER_NAME} ;
		    		my $cluster_delta = $cluster->{CLUSTER_DELTA} ;
		    		
		    		my %cluster = (
					# html attr for cluster
						COLOR => ( $tbody_object->[$index_page]{MASSES}[$index_mz]{COLOR}), 
						PARENT_ID => ( $tbody_object->[$index_page]{MASSES}[$index_mz]{NB_MASS}).'_0_0' , 
						NB_MASS => ( $tbody_object->[$index_page]{MASSES}[$index_mz]{NB_MASS}), 
						NB_CLUSTER_BY_MASS => $index_cluster+1, 
						NB_ENTRY_BY_MASS => 0, 
					# cluster features
						CLUSTER_TOTAL => ($cluster->{NB_ENTRIES_FOR_CLUSTER}), 
						CLUSTER_FORMULA => $$cluster_formula,
						CLUSTER_NAME => $$cluster_name, 
						CLUSTER_DELTA => $$cluster_delta, 
#						CLUSTER_RATIO => $cluster->{ISOTOPIC_RATIO},
					# entries group
						ENTRIES => [], ## end ENTRIES
					) ; ## end cluster 01
					push ( @{ $tbody_object->[$index_page]{MASSES}[$index_mz]{TRANSFORMS}[$index_transfo]{CLUSTERS} }, \%cluster) ;
					$index_cluster++ ;
				}
				$index_transfo++ ;
			}
			$index_mz++ ;
			$current_mz++ ;
		}
		$index_page++ ;
    }

    return($tbody_object) ;
}
## END of SUB


#				


=head2 METHOD sort_tbody_object

	## Description : sort cluster and entries by delta
	## Input : $tbody_object
	## Output : $tbody_object
	## Usage : my ( $tbody_object ) = sort_tbody_object ( $tbody_object ) ;
	
=cut
## START of SUB
sub sort_tbody_object {
    ## Retrieve Values
    my $self = shift ;
    my ( $tbody_object ) = @_;
    
    my $index_page = 0 ;
    
    ## foreach page
    foreach my $page (@{$tbody_object}) {
    	
    	my $index_mass = 0 ;
    	foreach my $masses_page ( @{ $page->{'MASSES'} } ) {
    		
    		my $index_transfo = 0 ;
    		foreach my $transforms_mass ( @{ $masses_page->{'TRANSFORMS'} } ) {
    			
    			if ($transforms_mass->{'CLUSTERS'}) {
	    				## sorted by score
	    			my @sorted = () ;
	    			my @temp = @{ $transforms_mass->{'CLUSTERS'} } ;
	    			if (scalar (@temp) > 1 ) { ## for mz without record (only one entry with NA or 0 values)
			    		@sorted = sort {  abs($a->{CLUSTER_DELTA}) <=> abs($b->{CLUSTER_DELTA}) } @temp ;
			    	}
			    	else {
			    		@sorted = @temp ;
			    	}
			    	$tbody_object->[$index_page]{'MASSES'}[$index_mass]{'TRANSFORMS'}[$index_transfo]{'CLUSTERS'} = \@sorted ;
    			}

    			$index_transfo++ ;
    		} ## end foreach transforms_mass
    		$index_mass++ ;
    	} ## end foreach masses_page
    	$index_page++ ;
    }  ## end foreach page
    
    return ($tbody_object) ;
}
### END of SUB


=head2 METHOD add_entry_to_mz_object

	## Description : initializes and builds the entries object (perl array) and link it with cluster
	## Input : $entries_results, $tbody_object 
	## Output : $entries_objects
	## Usage : my ( $entries_objects ) = add_entry_to_mz_object($entries_results, $tbody_object ) ;
	
=cut
## START of SUB
sub add_entry_to_tbody_object {
	## Retrieve Values
    my $self = shift ;
    my ( $transfo_masses, $clusters_results, $entries_results, $tbody_object ) = @_ ;
    
    my $index_page = 0 ;
    my $current_mz = 0 ; 
    
    foreach my $page (@{$tbody_object}) {
    	
    	my $index_mz = 0 ;

		foreach my $filtered_mz  ( @{ $tbody_object->[$index_page]{MASSES} }) {
			
			my $index_filtered_mz = undef ;
	    	
	    	if ($filtered_mz->{NB_MASS} ) {
	    		$index_filtered_mz = $filtered_mz->{NB_MASS}-1 ;
	    	}
	    	else{
	    		last;
	    	}
    	
			my $index_transfo = 0 ;
		
	    	foreach (@{$transfo_masses->[$index_filtered_mz]}) {
	    		my $index_cluster = 0 ;
	    		
	    		foreach my $cluster (@{$clusters_results->[$index_filtered_mz][$index_transfo]}) {
	    			my $index_entry = 0 ;
	    			
	    			foreach my $entry_name (@{$cluster->{'ENTRY_IDS'}}) { ## the part to fill
	    				
	    				foreach my $entry (@{$entries_results->[$index_filtered_mz][$index_transfo]}) { ## reference entries
	    					my $q_entry = $entry->{ID} ;
	    					
	    					## compare and matche only same entries
		    				if ($$entry_name eq  $$q_entry) {
		    					my ( $entry_formula, $entry_id, $entry_common, $entry_syst, $entry_delta ) = ( $entry->{FORMULA}, $entry->{ID}, $entry->{COMMON_NAME}, $entry->{SYST_NAME}, $entry->{DELTA} ) ;
	#	    					$index_entry++ ;
		    					
		    					my %entry_object = (
								# html attr for entry
									COLOR => ($tbody_object->[$index_page]{MASSES}[$index_mz]{COLOR}), 
									CLUSTER_ID => ( $tbody_object->[$index_page]{MASSES}[$index_mz]{TRANSFORMS}[$index_transfo]{CLUSTERS}[$index_cluster]{NB_CLUSTER_BY_MASS} ) , 
									NB_MASS => ( $tbody_object->[$index_page]{MASSES}[$index_mz]{TRANSFORMS}[$index_transfo]{CLUSTERS}[$index_cluster]{NB_MASS} ), 
									NB_CLUSTER_BY_MASS => ( $tbody_object->[$index_page]{MASSES}[$index_mz]{TRANSFORMS}[$index_transfo]{CLUSTERS}[$index_cluster]{NB_CLUSTER_BY_MASS} ), 
									NB_ENTRY_BY_MASS => $index_entry+1,
								# entry features
									LM_ID => $$entry_id, 
									ENTRY_FORMULA => $$entry_formula, 
									ENTRY_COMMONNAME => $$entry_common, 
									ENTRY_SYSTNAME => $$entry_syst, 
									MZ_DELTA => $$entry_delta,
								) ; ## end entry
								
		    					push (@{$tbody_object->[$index_page]{MASSES}[$index_mz]{TRANSFORMS}[$index_transfo]{CLUSTERS}[$index_cluster]{'ENTRIES'}}, \%entry_object) ;
		    				}
	    				}
	    				$index_entry++ ;
	    			} ## end foreach ENTRY
					$index_cluster++ ;
	    		} ## end foreach CLUSTER
				$index_transfo++ ;
	    	} ## end foreach TRANSFO
    		$index_mz++ ;
    		$current_mz++ ;
    	} ## end foreach MZ
    	$index_page++
    } ## end foreach PAGE

    return($tbody_object) ;
}
## END of SUB

1 ;


__END__

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc writer.pm

=head1 Exports

=over 4

=item :ALL is ...

=back

=head1 AUTHOR

Franck Giacomoni E<lt>franck.giacomoni@clermont.inra.frE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

version 1 : 26 / 11 / 2013

version 2 : 16 / 01/ 2014

=cut