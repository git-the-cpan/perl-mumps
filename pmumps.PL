my $script = <<'END_OF_SCRIPT';
~startperl~

use Language::Mumps qw(Config Runtime);
use Getopt::Std;

getopts("ftco:");

if ($#ARGV || $opt_c && $opt_t || $opt_o && !$opt_t) {
    die <<EOM;
$0 [-t [-o output_filename] | -c] [-f] filename.mps

-t Translate only
    -o Output to (Default: <filename>.pl)
-c Execute cached
-f Forgiveful: treat 8 leading spaces as tab
EOM
}

$filename = $ARGV[0];
$fn = $filename;
$fn .= ".mps" unless ($filename =~ /\./ || -f $filename);
die "$filename not found" unless (-f $fn);

$Language::Mumps::forgiveful = $opt_f;

if ($opt_t) {
    @out = split(/\./, $fn);
    pop @out if ($#out);
    $out = join(".", @out, "pl");
    $outf = $opt_o || $out;

    die "Can't create $outf" if ($outf eq $fn);

    Language::Mumps::translate($fn, $outf);
    exit;
}

if ($opt_c) {
    @out = split(/\./, $fn);
    pop @out if ($#out);
    $out = join(".", @out, "pl");
    $out .= "~" if ($out eq $fn);
    $srct = (stat($fn))[9];
    $dstt = (stat($out))[9];
    if ($srct > $dstt) {
        Language::Mumps::translate($fn, $out);
    }
    $@ = undef;
    do $out;
    die $@ if ($@);
    exit;
}

Language::Mumps::interprete($fn);
exit;

__END__

=head1 NAME

pmumps   - Stand alone ionterpreter for Language::Mumps

=head1 SYNOPSIS

prompt % C<pmumps file.mps>

prompt % C<pmumps -t -o file.pl file.mps>

prompt % C<pmumps -c file.mps>

prompt % C<pmumps -f file.mps>

=head1 DESCRIPTION

Translate a Mumps file to perl and run. (Unless B<-t> option is used for
translate only). Use B<->c to cache the compiled Perl script for next
executions. If you use B<-f>, pmumps will treat leading 8 spaces in a
line as
a leading tab.

=head1 CAVEATS

Edit your ~/.pmumps or /etc/pmumps.cf to enable persistent databases.

=head1 FILES

=over 6

=item F<$BINDIR/pmumps>
 Interpreter

=item F<~/.pmumps>
 User configuration

=item F</etc/pmumps.cf>
 Site configuration

=back
 
=head1 AUTHOR

Ariel Brosh, B<schop@cpan.org>

=head1 SEE ALSO

L<Language::Mumps>, L<DB_File>.

END_OF_SCRIPT
use Config;

my $file = __FILE__; $file =~ s/\.PL$//;

$script =~ s/\~(\w+)\~/$Config{$1}/eg;
if (!(open(FILE, ">$file"))  ||
    !(print FILE $script)  ||
    !(close(FILE))) {
    die "Error while writing $file: $!\n";
}
print "Extracted $file from ",__FILE__," with variable substitutions.\n";

if ( ! -f "/etc/pmumps.cf") {

$@ = undef;
eval { require File::Copy; import File::Copy; };

die "Can't copy configuration: $@" if $@;

copy("mumps.cfg", "/etc/pmumps.cf");

print "Created /etc/pmups.cf\n";

}
