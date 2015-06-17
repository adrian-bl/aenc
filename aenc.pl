#!/usr/bin/perl
use strict;

die "Usage: $0 FILE_LIST\n" unless int(@ARGV);

foreach my $input_file (@ARGV) {

	my($part_name) = $input_file =~ /^(.+)\.([^\.]+)$/;
	next unless $part_name;

	my $tmp_file = $part_name."_tmp.mp4";
	my $out_file = $part_name."_encoded.mp4";

	my @cmdlist = ('-i',         $input_file,
	               '-vf',        'scale=1024:576,subtitles=\''.$input_file.'\'',
	               '-c:v',       'libx264',
	               '-profile:v', 'baseline',
	               '-c:a',       'libfaac',
	               '-ar',        '44100',
	               '-ac',        '2',
	               '-b:a',       '128k',
	               '-preset',    'medium',
	               $tmp_file);

	unlink($tmp_file); # do not waste time waiting for input

	my $rv = system("ffmpeg-26", @cmdlist);
	rename($tmp_file, $out_file) if !$rv;
}
