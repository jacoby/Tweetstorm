#!/usr/bin/env perl

use feature qw'say state' ;
use subs qw'uniq' ;
use Data::Dumper ;
use List::Util qw{ first max min reduce shuffle } ;
use List::MoreUtils qw{ any all pairwise part natatime } ;

use Carp ;
use Data::Dumper ;
use Encode 'decode' ;
use Getopt::Long ;
use IO::Interactive qw{ interactive } ;
use Net::Twitter ;
use Pod::Usage ;
use WWW::Shorten 'TinyURL' ;
use YAML qw{ DumpFile LoadFile } ;

my $config = config() ;

tweetstorm($config) ;

exit ;

# ========= ========= ========= ========= ========= ========= =========
sub tweetstorm {
    my $config = shift ;

    my $twit = Net::Twitter->new(
        traits          => [qw/API::RESTv1_1/],
        consumer_key    => $config->{consumer_key},
        consumer_secret => $config->{consumer_secret},
        ssl             => 1,
        ) ;
    if ( $config->{access_token} && $config->{access_token_secret} ) {
        $twit->access_token( $config->{access_token} ) ;
        $twit->access_token_secret( $config->{access_token_secret} ) ;
        }
    unless ( $twit->authorized ) {

        # You have no auth token
        # go to the auth website.
        # they'll ask you if you wanna do this, then give you a PIN
        # input it here and it'll register you.
        # then save your token vals.

        say "Authorize this app at ", $twit->get_authorization_url,
            ' and enter the PIN#' ;
        my $pin = <STDIN> ;    # wait for input
        chomp $pin ;
        my ( $access_token, $access_token_secret, $user_id, $screen_name )
            = $twit->request_access_token( verifier => $pin ) ;
        save_tokens( $user, $access_token, $access_token_secret ) ;
        }

    my $status_id ;
    for my $status ( @{ $config->{storm} } ) {
        my $tweet ;
        $tweet->{status} = $status ;
        $tweet->{in_reply_to_status_id} = $status_id if $status_id ;
        if ( $twit->update($tweet) ) {
            say {interactive} $status ;
            my $profiles
                = $twit->lookup_users( { screen_name => $config->{user} } ) ;
            my $profile = shift @$profiles ;
            my $prev    = $profile->{status} ;
            $status_id = $profile->{status}->{id} ;
            }
        }
    }

# ========= ========= ========= ========= ========= ========= =========
sub config {
    my $config_file = $ENV{HOME} . '/.twitter.cnf' ;
    my $data        = LoadFile($config_file) ;

    my $config ;
    GetOptions(
        'file=s' => \$config->{file},
        'user=s' => \$config->{user},
        'count'  => \$config->{count},
        'help'   => \$config->{help},
        ) ;

    # $config->{status} = scrub( $config->{status} ) ;
    if (   $config->{help}
        || !$config->{file}
        || !-f $config->{file}
        || !$config->{user}
        || !$data->{tokens}->{ $config->{user} } ) {
        pod2usage(1) ;

        # pod2usage( { -verbose => 2, -exitval => 1 } ) if $opt->man ;
        exit ;
        }

    if ( open my $fh, '<', $config->{file} ) {
        my $c = 1 ;
        while (<$fh>) {
            chomp ;
            my $line = scrub($_) ;
            next if length $line < 1 ;
            pod2usage(1) if length $line > 130 ;
            $line .= qq{ ($c)} ;
            $c++ ;
            push @{ $config->{storm} }, $line ;
            }
        }
    for my $k (qw{ consumer_key consumer_secret }) {
        $config->{$k} = $data->{$k} ;
        }

    my $tokens = $data->{tokens}->{ $config->{user} } ;
    for my $k (qw{ access_token access_token_secret }) {
        $config->{$k} = $tokens->{$k} ;
        }
    return $config ;
    }

#========= ========= ========= ========= ========= ========= =========
sub restore_tokens {
    my ($user) = @_ ;
    my ( $access_token, $access_token_secret ) ;
    if ( $config->{tokens}{$user} ) {
        $access_token        = $config->{tokens}{$user}{access_token} ;
        $access_token_secret = $config->{tokens}{$user}{access_token_secret} ;
        }
    return $access_token, $access_token_secret ;
    }

#========= ========= ========= ========= ========= ========= =========
sub save_tokens {
    my ( $user, $access_token, $access_token_secret ) = @_ ;
    $config->{tokens}{$user}{access_token}        = $access_token ;
    $config->{tokens}{$user}{access_token_secret} = $access_token_secret ;

    #DumpFile( $config_file, $config ) ;
    return 1 ;
    }

#========= ========= ========= ========= ========= ========= =========
sub scrub {
    my $status = shift ;
    my @status = split /\s/, $status ;
    @status = map {
        my $s = $_ ;
        if ( $s =~ m{^https?://}i ) {
            $s = makeashorterlink($s) ;
            }
        $s ;
        } @status ;
    $status = join ' ', @status ;
    return $status ;
    }

=head1 NAME

tweetstorm.pl - flood Twitter with your idle thoughts

=head1 SYNOPSIS

    tweetstorm.pl -u username -f file

=head1 DESCRIPTION

This tool is for sending tweetstorms, a flood of numbered tweets, with each 
referring to the previous one for easy reading

=head1 OPTIONS

=over 4

=item B<-u>, B<--username>

The username this tweet will be sent as. Required.

=item B<-f>, B<--file>

A text file, with each line being less than 130 characters. URLs will be minimized. 
Each line will be numbered and tweeted.
Required.
The text to accompany the image. Required.

=item B<-h>, B<--help>

Display this text

=back

=head1 NOTES

To use this app, you need to have both a consumer key and secret, representing you
as a Twitter developer, and an access token and secret, representing you as a Twitter
user. These do not need to be the same Twitter account. 

Log into https://apps.twitter.com/ and click "Create New App", then store your 
consumer_key and consumer_secret in ${HOME}/.twitter.cnf. The application should
handle storing your access key and secret, but it will involve using a web browser to
finish the OAuth connection.

=head1 LICENSE

This is released under the Artistic 
License. See L<perlartistic>.

=head1 AUTHOR

Dave Jacoby L<jacoby.david@gmail.com>

=cut
