#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Pod-MinimumVersion.
#
# Pod-MinimumVersion is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Pod-MinimumVersion is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Pod-MinimumVersion.  If not, see <http://www.gnu.org/licenses/>.


use 5.004;
use strict;
use Test;
BEGIN { plan tests => 53; }

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Pod::MinimumVersion;

#------------------------------------------------------------------------------
{
  my $want_version = 49;
  ok ($Pod::MinimumVersion::VERSION, $want_version, 'VERSION variable');
  ok (Pod::MinimumVersion->VERSION,  $want_version, 'VERSION class method');
  {
    ok (eval { Pod::MinimumVersion->VERSION($want_version); 1 },
        1,
        "VERSION class check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { Pod::MinimumVersion->VERSION($check_version); 1 },
        1,
        "VERSION class check $check_version");
  }
  { my $pmv = Pod::MinimumVersion->new;
    ok ($pmv->VERSION, $want_version, 'VERSION object method');
    ok (eval { $pmv->VERSION($want_version); 1 },
        1,
        "VERSION object check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { $pmv->VERSION($check_version); 1 },
        1,
        "VERSION object check $check_version");
  }
}

#------------------------------------------------------------------------------
foreach my $data (
                  # command with no final newline
                  # provokes warnings from Pod::Parser itself though ...
                  # [ 0, "=head1" ],

                  [ 0, "=pod\n\nS<C<foo>C<bar>>" ],
                  # unterminated C<
                  [ 0, "=pod\n\nC<" ],

                  # doubles
                  [ 1, "=pod\n\nC<< foo >>" ],
                  [ 0, "=pod\n\nC<foo>" ],
                  [ 1, "=pod\n\nL< C<< foo >> >" ],

                  # Pod::MultiLang
                  [ 0, "=pod\n\nJ<< ... >>" ],

                  # links
                  [ 0, "=pod\n\nL<foo>" ],
                  [ 0, "=pod\n\nL<Foo::Bar>" ],

                  # links - alt text
                  [ 1, "=pod\n\nL<foo|bar>" ],
                  [ 0, "=pod\n\nL<foo|bar>", above_version => '5.005' ],
                  [ 2, "=pod\n\nL<C<< foo >>|S<< bar >>>" ],
                  [ 3, "=pod\n\nL<C<< foo >>|S<< bar >>>",
                    want_reports => 'alll' ],

                  # links - url
                  [ 1, "=pod\n\nL<http://www.foo.com/index.html>" ],
                  [ 1, "=pod\n\nL<http://www.foo.com/index.html>",
                    above_version => '5.006' ],
                  [ 0, "=pod\n\nL<http://www.foo.com/index.html>",
                    above_version => '5.008' ],

                  # links - url and text
                  # 5.005 for text, 5.012 for url+text
                  [ 2, "=pod\n\nL<some text|http://www.foo.com/index.html>" ],
                  [ 1, "=pod\n\nL<some text|http://www.foo.com/index.html>",
                    above_version => '5.010' ],
                  [ 0, "=pod\n\nL<some text|http://www.foo.com/index.html>",
                    above_version => '5.012' ],

                  [ 0, "=pos\n\nE<lt>\n" ],
                  [ 0, "=pos\n\nE<gt>\n" ],
                  [ 0, "=pos\n\nE<quot>\n" ],
                  # E<apos>
                  [ 1, "=pos\n\nE<apos>\n" ],
                  [ 0, "=pos\n\nE<apos>\n", above_version => '5.008' ],
                  # E<sol>
                  [ 1, "=pos\n\nE<sol>\n" ],
                  [ 0, "=pos\n\nE<sol>\n", above_version => '5.008' ],
                  # E<verbar>
                  [ 1, "=pos\n\nE<verbar>\n" ],
                  [ 0, "=pos\n\nE<verbar>\n", above_version => '5.008' ],

                  # =head3
                  [ 1, "=head3\n" ],
                  [ 0, "=head3\n", above_version => '5.008' ],
                  # =head4
                  [ 1, "=head4\n" ],
                  [ 0, "=head4\n", above_version => '5.008' ],

                  # =encoding
                  [ 1, "=encoding\n" ],
                  [ 1, "=encoding\n", above_version => '5.008' ],
                  [ 0, "=encoding\n", above_version => '5.010' ],

                  # =for
                  [ 1, "=for foo\n" ],
                  [ 1, "=for foo\n", above_version => '5.003' ],
                  [ 0, "=for foo\n", above_version => '5.004' ],
                  # =begin
                  [ 1, "=begin foo\n" ],
                  [ 1, "=begin foo\n", above_version => '5.003' ],
                  [ 0, "=begin foo\n", above_version => '5.004' ],
                  # =end
                  [ 1, "=end foo\n" ],
                  [ 1, "=end foo\n", above_version => '5.003' ],
                  [ 0, "=end foo\n", above_version => '5.004' ],

                 ) {
  my ($want_count, $str, @options) = @$data;
  # MyTestHelpers::diag "POD: $str";

  my $pmv = Pod::MinimumVersion->new (string => $str,
                                      @options);
  my @reports = $pmv->reports;

  # MyTestHelpers::diag explain $pmv;
  foreach my $report (@reports) {
    MyTestHelpers::diag ("-- ", $report->as_string);
  }
  # MyTestHelpers::diag explain \@reports;

  my $got_count = scalar @reports;
  require Data::Dumper;
  ok ($got_count, $want_count,
      Data::Dumper->new([$str],['str'])->Indent(0)->Useqq(1)->Dump
      . Data::Dumper->new([\@options],['options'])->Indent(0)->Dump);
}

foreach my $data (
                  [ undef,   "" ],
                  [ '5.005', "=for Pod::MinimumVersion use 5.005" ],
                  [ '5.005', "=for\t\tPod::MinimumVersion\t\tuse\t\t5.005" ],
                 ) {
  my ($want_version, $str, @options) = @$data;
  # MyTestHelpers::diag ("POD: ",$str);
  my $pmv = Pod::MinimumVersion->new (string => $str,
                                      @options);
  my @reports = $pmv->analyze;
  my $got_version = $pmv->{'for_version'};
  ok ($got_version, $want_version,
      '=for Pod::MinimumVersion use 5.005');
}

exit 0;
