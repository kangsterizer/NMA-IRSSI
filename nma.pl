#!/usr/bin/perl -w
# Copyright (c) 2012 kang@insecure.ws
# NMA notify() function, Copyright (c) 2010, Zachary West
# NMA notify() function, Copyright (c) Adriano Maia
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#    This product includes software developed by the <organization>.
# 4. Neither the name of the <organization> nor the
#    names of its contributors may be used to endorse or promote products
#    derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY <COPYRIGHT HOLDERS> ''AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# This script requires <http://www.notifymyandroid.com>

use strict;
use vars qw($VERSION %IRSSI);
use LWP::UserAgent;
use Getopt::Long;
use Pod::Usage;
use Irssi;

$VERSION = '0.0.1';
%IRSSI = (
        authors => 'kang',
        contact => 'kang@insecure.ws',
        name => 'nma',
        description => 'notifymyandroid helper',
        license => 'BSD, see above',
        changed => '$Date: 2012-08-06 12:00:00 +0100 (Mon, 06 Aug 2012) $'
);

my $hterm = 'kang';
my $apikey = '<fill me>';

Irssi::theme_register(
[
	 'nma_crap',
	  '{line_start}{hilight ' . $IRSSI{'name'} . ':} $0'
  ]);

sub priv_msg {
        my ($srv,$msg,$nick,$address,$target) = @_;
        if ($srv->{usermode_away}) {
                notify("Private message", $nick.": ".$msg);
        }
}

sub hilight {
        my ($dest, $text, $stripped) = @_;
        my $away;
	my $server;
        if ( ($stripped =~ m/$hterm/) && $dest->{level} & MSGLEVEL_HILIGHT) {
                foreach $server (Irssi::servers()) {
                        if ($server->{usermode_away}) {
                                $away=1;
                        }
                }
                if ($away) {
                        notify("Hilight", $dest->{target}.": ".$stripped);
                }
        }
}

sub notify {
        my ($type, $msg) = @_;
        my %options==();
        $options{'apikey'}=$apikey;
        $options{'application'}="IRSSI";
        $options{'event'}=$type;
        $options{'notification'}=$msg;
        $options{'priority'}=0;

        $options{'application'} =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
        $options{'event'} =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
        $options{'notification'} =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

        my ($userAgent, $request, $response, $requestURL);
        $userAgent = LWP::UserAgent->new;
        $userAgent->agent("NMA_IRSSI/1.0");
        $userAgent->env_proxy();

        $requestURL = sprintf("https://www.notifymyandroid.com/publicapi/notify?apikey=%s&application=%s&event=%s&description=%s&priority=%d",
                                        $options{'apikey'},
                                        $options{'application'},
                                        $options{'event'},
                                        $options{'notification'},
                                        $options{'priority'});

        $request = HTTP::Request->new(GET => $requestURL);

        $response = $userAgent->request($request);

        if (!$response->is_success) {
		Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'nma_crap', "Something went wrong: ".$response->content);
        }
}

Irssi::signal_add_last("message private", "priv_msg");
Irssi::signal_add_last("print text", "hilight");
