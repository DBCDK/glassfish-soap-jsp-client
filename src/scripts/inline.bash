#!/bin/bash -e

cd "$1"
ls $2
exec perl -0777 -pi -x "$0" $2




# START ON LINE 11 - PERL ERROR LINE +10
#!/usr/bin/perl

use strict;
use IO::File;

my %ENTITIES = (
    quot => '"',
    amp => '&',
    apos => "'",
    lt => '<',
    gt => '>'
);
my $ENTITIES_PATTERN = '&(' . join('|', sort keys %ENTITIES) . ');';

sub unescape($) {
    ($_) = @_;
    s{$ENTITIES_PATTERN}{$ENTITIES{$1}}msgeo;
    return $_;
}

sub processScript($$$$) {
    my($all,$tags,$content,$indent) = @_;
    $indent ||= '';
    my $hash = {$tags =~ m{(?:\s+(\w+)=([^\s>]*|\"[^\"]*\"|\'[^\']*\')?)}msg};
    for my $key (keys %$hash) {
	if($hash->{$key} =~ m{\"([^\"]*)\"}ms) {
	    $hash->{$key} = unescape($1);
	} elsif($hash->{$key} =~ m{\'([^\']*)\'}ms) {
	    $hash->{$key} = unescape($1);
	}
    }
    if(exists $hash->{type} && $hash->{type} eq 'text/javascript' && exists $hash->{src} ) {
	my $filename = $hash->{src};
	my $file = new IO::File($filename, 'r');
	die("Cannot inline file: $filename: $!\n") unless($file);
	$content .= <$file>;
	$file->close();
	return '<script type="text/javascript">' . $content . $indent . '</script>';
    } else {
	return $all;
    }
}

s{(<\s*script((?:\s+\w+=(?:[^\s>]*|\"[^\"]*\"|\'[^\']*\')?)*)\s*>(.*?)(^\s*)?<\s*/\s*script>)}{processScript($1,$2,$3,$4)}msge;


