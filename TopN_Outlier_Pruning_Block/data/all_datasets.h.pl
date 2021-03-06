#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use File::Util;

#===============================================================================
# Configuration
#===============================================================================
use constant DATASET_DIR => '../data';
#-------------------------------------------------------------------------------

sub get_dataset_name($) {
    my $dataset_path = $_[0];
    if ($dataset_path =~ m/^(.*\/)?([^\/]+)\.dat$/) {
        return $2;
    } else {
        return $dataset_path;
    }
}

sub clean_macro_name($) {
    my $macro_name = $_[0];
    $macro_name =~ s/-/_/g;
    return $macro_name;
}

# Make sure an output file was specified
scalar(@ARGV) >= 1 || die('No output file specified');
my $output_file = $ARGV[0];
open(OUTPUT, ">$output_file") || die("Cannot open output file: $output_file");

# Get the data sets
-d "${\(dirname($0))}/${\DATASET_DIR}" || die("Directory doesn't exist: $${\(dirname($0))}/${\DATASET_DIR}");
my $fu = File::Util->new;
my @dataset_files = $fu->list_dir("${\(dirname($0))}/${\DATASET_DIR}", '--files-only', '--no-fsdots', '--pattern=\.dat$', '--with-paths', '--recurse');
my @datasets = ();
for my $dataset_file (@dataset_files) {
    my $dataset_name = get_dataset_name($dataset_file);
    push(@datasets, $dataset_name);
}

# Start of header file
print OUTPUT <<EOF;
#ifndef ALL_DATASETS_H_
#define ALL_DATASETS_H_

#include "utility.h" /* for __BEGIN_DECLS, __END_DECLS */
#include <string> /* for std::string */

EOF

# Configuration
print OUTPUT <<EOF;
/*============================================================================*/
/* Configuration                                                              */
/*============================================================================*/
EOF
for my $dataset (@datasets) {
    printf OUTPUT "#define DO_TEST_%-30s 0\n", clean_macro_name($dataset);
}
print OUTPUT <<EOF;
/*----------------------------------------------------------------------------*/

__BEGIN_DECLS

EOF

# The actual data sets
print OUTPUT <<EOF;
/*============================================================================*/
/* The data sets                                                              */
/*============================================================================*/
EOF
for my $dataset_file (@dataset_files) {
    my $dataset_name = get_dataset_name($dataset_file);

    print OUTPUT <<EOF;
#if DO_TEST_${\(clean_macro_name($dataset_name))}
    #include "${\(basename($dataset_file))}.h"
#endif /* #if DO_TEST_${\(clean_macro_name($dataset_name))} */
EOF
}
print OUTPUT <<EOF;
/*----------------------------------------------------------------------------*/

EOF

# The test method
print OUTPUT <<EOF;
static int test_embedded_dataset(const std::string & dataset) {
EOF

for my $dataset (@datasets) {
    print OUTPUT <<EOF;
#if DO_TEST_${\(clean_macro_name($dataset))}
    if (dataset == "$dataset") {
        return test_from_array("${dataset}", dataset_${dataset});
    }
#endif /* #if DO_TEST_${\(clean_macro_name($dataset))} */
EOF
}

# Error message if data set not found
print OUTPUT <<EOF;
    PRINTF_STDERR("Data set not found: " << dataset << std::endl);
    PRINTF_STDERR("Available datasets are:" << std::endl);
EOF
for my $dataset (@datasets) {
    print OUTPUT <<EOF;
#if DO_TEST_DATASET_${\(clean_macro_name($dataset))}
    PRINTF_STDERR("    " << "$dataset" << std::endl);
#endif /* #if DO_TEST_${\(clean_macro_name($dataset))} */
EOF
}
print OUTPUT <<EOF;
    return -2;
}
EOF

# End of header file
print OUTPUT <<EOF;

__END_DECLS

#endif /* #ifndef ALL_DATASETS_H_ */
EOF
close(OUTPUT);