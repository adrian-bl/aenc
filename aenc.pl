#!/usr/bin/perl
use strict;
use Getopt::Long;

my $getopts = {};
GetOptions($getopts, "hardsub", "nosub", "mp4", "hq") or exit 1;


die "Usage: $0 [--hardsub --nosub --mp4 --hq] FILE_LIST\n" unless int(@ARGV);

my $FEXT = ($getopts->{mp4} ? "mp4" : "mkv");
my $EEXT = ($getopts->{hq}  ? "_hq-encoded" : "_encoded");
my $RES  = ($getopts->{hq}  ? "1028:544" : "1024:576");
my $CRF  = ($getopts->{hq}  ? 18 : 22);

# mp4 does not support embedded subs: enable hardsub unless copy was disabled
$getopts->{hardsub} = 1 if $getopts->{mp4} && !$getopts->{nosub};

foreach my $input_file (@ARGV) {

	my($part_name) = $input_file =~ /^(.+)\.([^\.]+)$/;
	next unless $part_name;

	my $tmp_file = $part_name."_tmp.$FEXT";
	my $out_file = $part_name.$EEXT.".".$FEXT;
	my $scaler   = 'scale='.$RES;
	   $scaler  .= ',subtitles=\''.$input_file.'\'' if ($getopts->{hardsub});

	my @cmdlist = ('-i',         $input_file,
	               '-vf',        $scaler,
	               '-c:v',       'libx264',
	               '-c:a',       'aac',
	               '-strict',    '-2',
	               '-ar',        '44100',
	               '-ac',        '2',
	               '-clev',      '1.814',
	               '-slev',      '.5',
	               '-b:a',       '128k',
	               '-preset',    'medium',
	               '-tune',      'animation',
	               '-crf',       $CRF);

	if (!$getopts->{mp4} && !$getopts->{nosub} && !$getopts->{hardsub}) {
		push(@cmdlist, qw(-scodec copy));
	} else {
		push(@cmdlist, qw(-sn));
	}

	unlink($tmp_file); # do not waste time waiting for input

	my $rv = system("ffmpeg", @cmdlist, $tmp_file);
	rename($tmp_file, $out_file) if !$rv;
}
