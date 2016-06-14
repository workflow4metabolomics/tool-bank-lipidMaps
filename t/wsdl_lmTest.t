#! perl
use diagnostics;
use warnings;
no warnings qw/void/;
use strict;
no strict "refs" ;
use Test::More qw( no_plan );
#use Test::More tests => 29 ;
use FindBin ;

## Specific Modules
use lib $FindBin::Bin ;
my $binPath = $FindBin::Bin ;
use lib::lmTest qw( :ALL ) ;

my $current_test = 0 ;

print "\n\t\t\t\t  * * * * * * \n" ;
print "\t  * * * - - - Test LiPIDMAPS Main script - - - * * * \n\n" ;
	
print "\n** Test $current_test build_lm_mass_query with no fam/class/subcl **\n" ; $current_test++;
	
is( build_lm_mass_queryTest('0.5', 'NA', 'NA_1', 'NA_101'),'http://www.lipidmaps.org/data/structure/LMSDSearch.php?Mode=ProcessTextSearch&OutputColumnHeader=No&OutputMode=File&OutputType=TSV&ExactMassOffSet=0.5&ExactMass=', 'Works with no cat, no class and no subcl argvt' ) ;

print "\n** Test $current_test build_lm_mass_query with a fam but no class/subcl **\n" ; $current_test++;
is( build_lm_mass_queryTest('0.5', 1, 'NA_1', 'NA_101'),'http://www.lipidmaps.org/data/structure/LMSDSearch.php?Mode=ProcessTextSearch&OutputColumnHeader=No&OutputMode=File&OutputType=TSV&CoreClass=1&ExactMassOffSet=0.5&ExactMass=', 'Works with a cat, but no class and no subcl argvt' ) ;

print "\n** Test $current_test build_lm_mass_query with a fam/class but no subcl **\n" ; $current_test++;
is( build_lm_mass_queryTest('0.5', 1, 101, 'NA_101'),'http://www.lipidmaps.org/data/structure/LMSDSearch.php?Mode=ProcessTextSearch&OutputColumnHeader=No&OutputMode=File&OutputType=TSV&CoreClass=1&MainClass=101&ExactMassOffSet=0.5&ExactMass=', 'Works with a cat, a class but no subcl argvt' ) ;

print "\n** Test $current_test build_lm_mass_query with a fam/class/subcl **\n" ; $current_test++;
is( build_lm_mass_queryTest('0.5', 1, 101, 10101),'http://www.lipidmaps.org/data/structure/LMSDSearch.php?Mode=ProcessTextSearch&OutputColumnHeader=No&OutputMode=File&OutputType=TSV&CoreClass=1&MainClass=101&SubClass=10101&ExactMassOffSet=0.5&ExactMass=', 'Works with a cat, a class and a subcl argvt' ) ;

print "\n** Test $current_test round_nums with a list of float and a decimal reduction of 1 **\n" ; $current_test++;
is_deeply( round_numsTest(
		['175.01', '238.19', '420.16', '780.32', '956.25', '1100.45' ], 1 ), 
		['175.0', '238.2', '420.2', '780.3', '956.2', '1100.5' ], 
		'Method \'round_nums\' works with a list of float and return a well rounded list');
		
print "\n** Test $current_test round_nums with a list of float and a decimal reduction of 0 **\n" ; $current_test++;
is_deeply( round_numsTest(
		['175.01', '238.19', '420.16', '780.32', '956.25', '1100.45', '111.6' ], 0 ), 
		['175', '238', '420', '780', '956', '1100', '112' ], 
		'Method \'round_nums\' works with a list of float and return a well rounded list');





