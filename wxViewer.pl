#!/usr/bin/perl

use strict;
use warnings;
use Devel::SimpleTrace;

use lib './lib';
use wxViewer;

my $wxviewer = wxViewer->new();
$wxviewer->MainLoop();
