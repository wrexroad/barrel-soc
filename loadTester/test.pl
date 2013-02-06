#!/usr/bin/perl

open TEST, "110901_1052041.bar" or print "cant open input file\n";

while(read TEST, $buffer, 214){
	print $buffer."\n";
}

close TEST;
