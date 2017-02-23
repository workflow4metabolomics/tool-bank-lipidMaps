## ****** Lipidmaps environnemnt : ****** ##
# version 2016.09.27 M Landi / F Giacomoni - INRA - METABOHUB - workflow4metabolomics.org core team

## --- PERL compilator / libraries : --- ##
$ perl -v
This is perl, v5.10.1 (*) built for x86_64-linux-thread-multi

# libs CORE PERL : 
use strict ;
no strict "refs" ;
use warnings ;
use Carp qw (cluck croak carp confess) ;
use Exporter ;
use diagnostics ;
use Data::Dumper ;
use POSIX ;
use Getopt::Long ;
use FindBin;

# libs CPAN PERL : 
use LWP::UserAgent ;
use Text::CSV ;
use HTML::Template ;
use XML::Twig;
use Time::HiRes;

$ sudo perl -MCPAN -e shell
cpan> install Text::CSV

# libs pfem PERL : libs are now integrated
use lib::conf  qw( :ALL ) ;
use lib::csv  qw( :ALL ) ;
use lib::operations  qw( :ALL ) ;
--

## --- Conda compliant --- ##
This tool and its PERL dependencies are "Conda compliant".

## --- R bin and Packages : --- ##
NA
-- 

## --- Binary dependencies --- ##
NA - use only lipidmaps ws (http://www.lipidmaps.org/data/structure/LMSDSearch.php)
--

## --- Config : --- ##
JS and CSS (used in HTML output format) are now hosted on cdn.rawgit.com server - no local config needed
--

## --- XML HELP PART --- ##
one image :
lipidmaps.png
--

## --- DATASETS OR TUTORIAL --- ##
Please find help on W4M: http://workflow4metabolomics.org/howto 
--

## --- ??? COMMENTS ??? --- ##
The Lipidmaps WS ask to sleep 20s between each query... 
To use full funtionalities of html output files : 
  - check that sanitize_all_html option in universe_wsgi.ini file is uncomment and set to FALSE.
--