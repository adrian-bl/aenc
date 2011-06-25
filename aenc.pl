#!/usr/bin/perl
use strict;
use Getopt::Long;

my $opts = {};

GetOptions($opts, "profile=s", "hardsub");

my $subclass = Aenc::Init->($opts->{profile});

die "Usage: $0 --profile=[legend|defy|defyhq|hq2] [--hardsub] INPUT\n" unless $subclass;

foreach my $infile (@ARGV) {
	my ($outfile) = $infile =~ /(.+)\....$/;
	my @cmd       = ();
	$outfile    ||= int(rand(0xFFFFF));
	$outfile     .= "-android-$opts->{profile}.mp4";
	print "> Encoding $infile -> $outfile\n";
	
	if($opts->{hardsub}) {
		$subclass->do_hardsub($infile,$outfile);
	}
	else {
		$subclass->do_mpeg4($infile,$outfile);
	}
	
}

package Aenc;
	sub Init {
		my($pn) = @_;
		return Aenc::Legend->new   if $pn eq 'legend';
		return Aenc::Defy->new     if $pn eq 'defy';
		return Aenc::DefyHQ->new   if $pn eq 'defyhq';
		return Aenc::HQ2->new      if $pn eq 'hq2';
		return undef;
	}
1;

package Aenc::Generic;
	
	###############################################
	# Display generic info
	sub info {
		my($self,$msg) = @_;
		print "[info] $msg\n";
	}
	
	###############################################
	# Critical / Error messages
	sub critical {
		my($self,$msg) = @_;
		print "[crit] $msg\n";
	}
	
	###############################################
	# Run mencoder to hardsub $infile - returns name of tempfile
	sub do_mencoder_hardsub {
		my($self,$infile) = @_;
		my $tmp = "tmp.$$.".int(rand(0xFFFF)).".avi";
		$self->info("Creating tempfile ($tmp)");
		system("mencoder", "-oac", "mp3lame", "-lameopts", "preset=insane", "-ovc", "lavc", "-lavcopts", "vcodec=ffv1", "-o", $tmp, $infile);
		return $tmp;
	}
	
	###############################################
	# Create a hardsub - then call mpeg4 encoder
	sub do_hardsub {
		my($self,$in,$out) = @_;
		my $hsub = $self->do_mencoder_hardsub($in);
		if(-f $hsub) {
			$self->do_mpeg4($hsub,$out);
			unlink($hsub) or die "Could not unlink `$hsub': $!\n";
		}
		else {
			$self->critical("Failed to mencode `$in'");
			unlink($hsub);
		}
	}
	
	###############################################
	# Call ffmpeg to create an mpeg4 file
	sub do_mpeg4 {
		my($self,$in,$out) = @_;
		$self->info("Converting `$in' into `$out'");
		
		if($self->do_twopass) {
			foreach my $pass (1..2) {
				print "# pass $pass\n";
				my @ff = ("ffmpeg", "-y", "-pass", $pass, "-i", $in,$self->get_vcodec_args, $self->get_vcodec_extargs, $self->get_acodec_args, $out);
				$self->info(join(" ",@ff));
				system(@ff);
			}
		}
		else {
			my @ff = ("ffmpeg", "-i", $in,$self->get_vcodec_args, $self->get_vcodec_extargs, $self->get_acodec_args, $out);
			$self->info(join(" ",@ff));
			system(@ff);
		}
	}
	
	###############################################
	# Return (generic) faac opts
	sub get_acodec_args {
		my($self) = @_;
		return qw(-acodec libfaac -ab 128k);
	}
	
	###############################################
	# Return (generic) x264 opts
	sub get_vcodec_args {
		return qw(-vcodec libx264 -s 480x272 -b 480k -maxrate 1024k -bufsize 2M);
	}
	
	###############################################
	# even more x264 opts!
	sub get_vcodec_extargs {
		return qw(-profile baseline -threads 0);
	}
	
	sub do_twopass {
		return 0;
	}
	
1;

package Aenc::Legend;
	use base 'Aenc::Generic';
	
	sub new {
		my($classname,%args) = @_;
		my $self = {};
		return bless($self,$classname);
	}
	
1;

package Aenc::DefyHQ;
	use base 'Aenc::Generic';
	sub new {
		my($classname,%args) = @_;
		my $self = {};
		return bless($self,$classname);
	}
	###############################################
	# Set resolution to native-defyness
	sub get_vcodec_args {
		return qw(-vcodec libx264 -s 854x480 -b 950k -maxrate 1900k -bufsize 2M);
	}
1;

package Aenc::Defy;
	use base 'Aenc::Generic';
	sub new {
		my($classname,%args) = @_;
		my $self = {};
		return bless($self,$classname);
	}
	###############################################
	# Set resolution to native-defyness
	sub get_vcodec_args {
		return qw(-vcodec libx264 -s 640x360 -b 400k -maxrate 800k -bufsize 2M);
	}
1;


package Aenc::HQ2;
	use base 'Aenc::Generic';
	sub new {
		my($classname,%args) = @_;
		my $self = {};
		return bless($self,$classname);
	}
	
	sub do_twopass {
		return 1;
	}
	
	###############################################
	# Set resolution to native-defyness
	sub get_vcodec_args {
		return qw(-vcodec libx264 -s 854x480 -b 950k -maxrate 1900k -bufsize 2M);
	}
	
1;

