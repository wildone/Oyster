=xml
<document title="Oyster Testing Framework">
    <synopsis>
        This script runs all test scripts and returns the totalled test results.
    </synopsis>
    <todo>
        A 'how to' doc for creating tests.
    </todo>
    <todo>
        Use IPC::Open3 instead of `` to run tests and redirect STDERR.
    </todo>
    <todo>
       Print success/failure on -d for convenience
    </todo>
    <todo>
       Change success/failure to pass/fail
    </todo>
=cut
package oyster::script::test;

# this purposefully does NOT use the oyster environment! otherwise, we couldn't test it.

# parse command line args
# TODO: something better than this
our %args;
$args{'d'} = $ARGV[1] if $ARGV[0] eq '-d';

# variables
our @tests; # hashref with meta data of each test with some extra variables
            # added

# introduction
print "Beginning Test Suite...\n" unless exists $args{'d'};

# iterate through directories and populate test data
test_dir('');

# print totals
print_totals() unless exists $args{'d'};

# functions

# prints a summary of test results
sub print_totals {
    print "\nTest Results:\n";

    # assemble variables
    my $num_tests  = scalar @tests; # total number of tests
    my $num_tested = 0;             # number of tests actually run (not skipped)
    my @failures;                   # an array of failed tests (each value is an index in @tests)
    my $i = 0;
    for my $test (@tests) {
        next if $test->{'skip'};
        $num_tested++;
        push(@failures, $i) unless $test->{'result'};
        $i++;
    }
    my $num_skipped = $num_tests - $num_tested;
    my $num_failed  = scalar @failures;
    my $num_passed  = $num_tested - $num_failed;

    # print results
    print "  $num_tests total tests\n\n";
    print "  $num_tested (" . (sprintf('%.2f', $num_tested / $num_tests) * 100) . "\%) tests run\n";
    print "  $num_skipped (" . (sprintf('%.2f', $num_skipped / $num_tests) * 100) . "\%) tests skipped \n";
    print "  $num_passed (" . (sprintf('%.2f', $num_passed / $num_tested) * 100) . "\%) passed\n";
    print "  $num_failed (" . (sprintf('%.2f', $num_failed / $num_tested) * 100) . "\%) failed\n";
    for my $i (@failures) {
        my $test = $tests[$i];
        print "    $test->{name}\n";
    }
    # might want to reset @tests here in case some day a script runs more than one sequence of tests
}

# iterates through a directory and all sub-directories, testing as necessary and adding data to @tests
sub test_dir {
    my $path = shift;

    # open directory to iterate over
    my $full_path = "./$path";
    opendir(my $dir, $full_path) or die "Error reading directory './$path':\n$!\n";

    # check if this directory has tests in it, add them to @tests
    my $tests_path = "${full_path}tests/";
    if (-d $tests_path) {
        opendir(my $tests_dir, $tests_path) or die "Error reading test directory '$tests_path':\n$!\n";
        print "\nTesting Directory: $path\n\n" unless exists $args{'d'};
        while (my $file = readdir($tests_dir)) {
            next unless $file =~ /\.test$/o;

            # read the test file
            my $test;
            unless ($test = do "$tests_path$file") {
                die "Error parsing: '$tests_path$file'"               if $@;
                die "Error reading: '$tests_path$file': $!"           unless defined $test;
                die "File did not return a value: '$tests_path$file'" unless $test;
            }

            # if the file contains multiple tests
            if (ref $test eq 'ARRAY') {
                for my $subtest (@{$test}) {
                    run_test($subtest);
                }
            }

            # if the file contained a single test
            elsif (ref $test eq 'HASH') {
                run_test($test);
            }

            # wtf?
            else {
                die "Test did not return valid data: '$tests_path$file'";
            }
        }
    }

    # iterate through directories in the current directory
    while (my $file = readdir($dir)) {
        next if ($file eq '.' or $file eq '..' or $file eq 'tests' or $file eq '.svn');
        test_dir("$path$file/") if -d "$full_path$file/";
    }
}

sub run_test {
    my $test = shift;
    $test->{'source'} = preprocess_test_source($test->{'source'});

    if (exists $args{'d'}) {
        if ($args{'d'} == scalar @tests + 1) {
            print "Diagnosing '$test->{name}' (#" . scalar @tests + 1 .")...\n";
            print "  $test->{description}\n" if length $test->{'description'};
            print "### SOURCE ########################\n";
            chomp($test->{'source'});
            print $test->{'source'} . "\n";
            print "### EXPECTED OUTPUT ###############\n";
            print $test->{'output'} . "\n";
            print "### ACTUAL OUTPUT #################\n";
            my $test_file  = './tmp/test.tmp';
            open my $fh, '>', $test_file or die "Error creating temporary test file: $!";
            print $fh $test->{'source'};
            close $fh;
            my $output = `perl $test_file$test->{'args'}`;
            chomp($output);
            print $output . "\n";
            unlink $test_file;
            exit;
        }
        push(@tests, $test);
        return;
    }

    print "  Running '$test->{name}' (#" . scalar @tests + 1 .")...\n";
    print "    $test->{description}\n" if length $test->{'description'};
    if ($test->{'skip'}) {
        print "    - Skipped -\n";
    } else {
        my $test_file  = './tmp/test.tmp';
        my $error_file = './tmp/test.error';
        open my $fh, '>', $test_file or die "Error creating temporary test file: $!";
        print $fh $test->{'source'};
        close $fh;
        my $output = `perl $test_file$test->{'args'} 2>$error_file`;
        if (-e $error_file) {
            local $/ = 1;
            open my $errfh, '<', $error_file or die "Error reading test error file: $!";
            my $error = <$errfh>;
            chomp($error);
            if (length $error) {
                print "    An error occured while running the test:\n";
                print $error . "\n";
                $test->{'result'} = 0;
            }
            else {
                $test->{'result'} = $output eq $test->{'output'} ? 1 : 0 ;
            }
            close $errfh;
            unlink $error_file;
        } else {
            $test->{'result'} = $output eq $test->{'output'} ? 1 : 0 ;
        }
        print $test->{'result'} ? "    [ Pass ]\n" : "    ! Failure !\n" ;
        unlink $test_file;
    }
    push(@tests, $test);
}

sub preprocess_test_source {
    my $source = shift;

    $source =~ s~^#!CONFIG_PREAMBLE~BEGIN {
    our \$config = eval { require './config.pl' };
    die "Could not read ./config.pl, are you sure you are executing this script from your shared directory: \$@" if \$@;
}~o;

    return $source;
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008