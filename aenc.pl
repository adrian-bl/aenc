#!/usr/bin/perl
use strict;
use Getopt::Long;

my $opts = {};

GetOptions($opts, "rock", "ffmpeg", "combo");


foreach my $infile (@ARGV) {
	my ($outfile) = $infile =~ /(.+)\....$/;
	my @cmd       = ();
	$outfile    ||= int(rand(0xFFFFF));
	$outfile     .= "-android";
	print "> Encoding $infile -> $outfile\n";
	
	if($opts->{rock}) {
		@cmd = get_rockplayer($infile,$outfile);
	}
	elsif($opts->{ffmpeg}) {
		@cmd = get_ffmpeg($infile,$outfile);
	}
	elsif($opts->{combo}) {
		@cmd = get_combo($infile,$outfile);
	}
	else {
		die "Missing encoder mode (--rock | --ffmpeg | --combo)\n";
	}
	system(@cmd);
}




sub get_rockplayer {
	my($in,$out) = @_;
	my @args = qw(-vf scale=480:272 -ovc lavc -oac mp3lame -lavcopts vcodec=mpeg4:vhq:vbitrate=850 -ofps 24000/1001);
	return('mencoder', $in, '-o', $out.".avi", @args);
}

sub get_ffmpeg {
	my($in,$out) = @_;
	
	my @args = qw(-threads 0 -acodec libfaac -ab 128k -s 480x272 -aspect 16:9 -vcodec libx264
	              -b 450k -flags +loop -cmp +chroma
	              -partitions +parti4x4+partp8x8+partb8x8
	              -flags2 +mixed_refs -me_method umh -subq 5
	              -trellis 1 -refs 5 -coder 0 -me_range 16
	              -g 250 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71
	              -bt 450k -maxrate 768k -bufsize 2M
	              -rc_eq 'blurCplx^(1-qComp)' -qcomp 0.6 -qmin 10
	              -qmax 51 -qdiff 4 -level 13);
	return('ffmpeg', '-i', $in, @args, $out.".mp4");
}

sub get_combo {
	my($in,$out) = @_;
	my $tmp  = "tmp$$.avi";
	system("mencoder", "-oac", "mp3lame", "-ovc", "lavc", "-lavcopts", "vcodec=mpeg4:vbitrate=5120000", "-o", $tmp, $in);
	system(get_ffmpeg($tmp, $out));
	return("rm", $tmp);
}
