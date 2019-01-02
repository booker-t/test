use strict;

use LWP::Protocol::Net::Curl;
use LWP::UserAgent;
 
my $ua = LWP::UserAgent->new;
my $res = $ua->get(
    'https://api.github.com/users/booker-t',
    X_CurlOpt_Verbose => 1,
);

print $res -> as_string, "\n";

if ($res -> as_string =~ /HTTP\/1\.1 200 OK/) {
	print "Authentification OK\n";

	my $res = $ua->get(
    'https://api.github.com/users/booker-t/repos',
    X_CurlOpt_Verbose => 1,
	);

	print $res -> as_string, "\n";

# "commits_url": "https://api.github.com/repos/booker-t/test/commits{/sha}",


} else {
  print "Authentification Error\n";
}
