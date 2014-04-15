## ****** Lipidmaps environnemnt : ****** ##
# version 01 2014 M Landi / F Giacomoni

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
use LWP::Simple ;
use HTML::Template ;
use XML::Twig;

# libs pfem PERL : include the lib called pfem-perl in your PERL5LIB path. This lib is available in the ABIMS toolshed "Tool Dependency Packages" category.
use conf::conf  qw( :ALL ) ;
use formats::csv  qw( :ALL ) ;
use maths::operations  qw( :ALL ) ;
--

## --- R bin and Packages : --- ##
No interaction with R
-- 

## --- Binary dependencies --- ##
No interaction with binary - use only lipidmaps ws (http://www.lipidmaps.org/data/structure/LMSDSearch.php)
--

## --- Config : --- ##
Edit the following lines in the config file : ~/metabolomics/Identification/Banks_Queries/Lipidmaps/lipidmaps.conf
JS_GALAXY_PATH=http://YOUR_GALAXY_HOSTNAME/static/scripts/libs/outputs
CSS_GALAXY_PATH=http://YOUR_GALAXY_HOSTNAME/static/style
HTML_TEMPLATE=absolute_path_to_/lipidmaps.tmpl
--

## --- XML HELP PART --- ##
Copy the following images in ~/static/images/metabolomics : 
--

## --- DATASETS --- ##
No data set ! waiting for galaxy pages
--

## --- ??? COMMENTS ??? --- ##
The Lipidmaps WS ask to sleep 20s between each query... 
To use full funtionalities of html output files : 
  - check that sanitize_all_html option in universe_wsgi.ini file is uncomment and set to FALSE.
  - copy the following JS files in YOUR_GALAXY_PATH/static/scripts/libs/outputs/ : jquery.simplePagination.js, main.js, shBrushJScript.js, shCore.js
  - copy the following CSS files in YOUR_GALAXY_PATH/static/style/ : simplePagination.css
 Their files (pfem-js and pfem-css) are available in the ABIMS toolshed "Tool Dependency Packages" category.
--