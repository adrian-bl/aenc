#!/usr/bin/perl
use strict;
use Getopt::Long;

my $getopts = {};
GetOptions($getopts, "nosubs") or exit 1;


die "Usage: $0 FILE_LIST\n" unless int(@ARGV);


foreach my $input_file (@ARGV) {

	my($part_name) = $input_file =~ /^(.+)\.([^\.]+)$/;
	next unless $part_name;

	my $tmp_file = $part_name."_tmp.mp4";
	my $out_file = $part_name."_encoded.mp4";
	my $scaler   = 'scale=1024:576';
	   $scaler  .= ',subtitles=\''.$input_file.'\'' unless $getopts->{nosubs};

	my @cmdlist = ('-i',         $input_file,
	               '-vf',        $scaler,
	               '-c:v',       'libx264',
	               '-c:a',       'libfaac',
	               '-ar',        '44100',
	               '-ac',        '2',
	               '-clev',      '1.814',
	               '-slev',      '.5',
	               '-b:a',       '128k',
	               '-preset',    'medium',
	               '-tune',      'animation',
	               '-crf',       22,
	               $tmp_file);

	unlink($tmp_file); # do not waste time waiting for input

	my $rv = system("ffmpeg", @cmdlist);
	rename($tmp_file, $out_file) if !$rv;
}
