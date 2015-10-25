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

## testing manage_atoms
print "\n-- Test rest url building \n\n" ;
is( build_lm_mass_queryTest('0.5', 'NA', 'NA_1', 'NA_101'),'http://www.lipidmaps.org/data/structure/LMSDSearch.php?Mode=ProcessTextSearch&OutputColumnHeader=No&OutputMode=File&OutputType=TSV&ExactMassOffSet=0.5&ExactMass=', 'Works with no cat, no class and no subcl argvt' ) ;

is( build_lm_mass_queryTest('0.5', 1, 'NA_1', 'NA_101'),'http://www.lipidmaps.org/data/structure/LMSDSearch.php?Mode=ProcessTextSearch&OutputColumnHeader=No&OutputMode=File&OutputType=TSV&CoreClass=1&ExactMassOffSet=0.5&ExactMass=', 'Works with a cat, but no class and no subcl argvt' ) ;

is( build_lm_mass_queryTest('0.5', 1, 101, 'NA_101'),'http://www.lipidmaps.org/data/structure/LMSDSearch.php?Mode=ProcessTextSearch&OutputColumnHeader=No&OutputMode=File&OutputType=TSV&CoreClass=1&MainClass=101&ExactMassOffSet=0.5&ExactMass=', 'Works with a cat, a class but no subcl argvt' ) ;

is( build_lm_mass_queryTest('0.5', 1, 101, 10101),'http://www.lipidmaps.org/data/structure/LMSDSearch.php?Mode=ProcessTextSearch&OutputColumnHeader=No&OutputMode=File&OutputType=TSV&CoreClass=1&MainClass=101&SubClass=10101&ExactMassOffSet=0.5&ExactMass=', 'Works with a cat, a class and a subcl argvt' ) ;



