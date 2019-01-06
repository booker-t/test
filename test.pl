use strict;

use LWP::Protocol::Net::Curl;
use LWP::UserAgent;
use Date::Calc qw(:all);

my $login = $ARGV[0];
 
unless ($login) {
	die "For run script need login. Example:\n\ttest.pl my_login\n";
}

my $ua = LWP::UserAgent->new;

#Получаем список репозиториев, вся простыня сообщений
my $res = $ua->get(
	'https://api.github.com/users/'.$login.'/repos',
  X_CurlOpt_Verbose => 1,
);

my $repo_data = $res -> as_string;

#Конкретно сам список репозиториев в массиве
my @repos = $repo_data =~ /"name": "(.*?)"/sg;

if (@repos) {

	#Немного шаманим с датой, прокручиваем на год назад от сегодняшнего дня
	my ($year, $month, $day) = Today(3);

	$month =~ s{^(\d)$}{0$1};
	$day =~ s{^(\d)$}{0$1};
  $year = $year - 1;

	for (@repos) {
		my $repo = $_;
		my $res = $ua->get(
  	  'https://api.github.com/repos/booker-t/'.$repo.'/commits?since='.$year.'-'.$month.'-'.$day.'T00:00:00Z',
  	  #X_CurlOpt_Verbose => 1,
		);

		my $data = $res -> as_string;

		#Получаем даты коммитов
		my @dates = $data =~ /"committer": \{\s+"name".*?"date": "(\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d)Z"\s+\}/sg;
		$_ =~ s{T}{ }g for @dates;

		my $table;

		#Если даты есть начинаем формировать таблицу
		for (@dates) {
			$_ =~ /(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):\d\d:\d\d/;
			my $year = $1;
			my $month = $2;
			my $day = $3;
			my $hour = $4;
			my $dofw = Day_of_Week($year,$month,$day);
			$hour =~ s{0(\d)}{$1};

			if ($table -> {$dofw} -> {$hour}) {
				$table -> {$dofw} -> {$hour}++;
			} else {
				$table -> {$dofw} -> {$hour} = 1;
			}

		}

		#Пустые ячейки таблицы заполняем нулями
		for (1..7) {
			my $dow = $_;
			if ($table -> {$dow}) {
				for (0..23) {
					$table -> {$dow} -> {$_} = 0 unless $table -> {$dow} -> {$_}; 
				}
			} else {
				for (0..23) {
					$table -> {$dow} -> {$_} = 0; 
				}
			}
		}

		#Рисуем таблицу в консоль
		print "\n", $repo, ":\n";

		print "   |";
		print " " for 0..85;
		print "\n";
		print "   |  ";

		for (0..23) {
			if ($_ < 9) {
				print $_."  ";
			} else {
				print $_."  ";
			}
		}
		print "\n";
		print "___|";
		print "_" for 0..85;
		print "\n";

		foreach my $key (sort keys %$table) {
			print "   |\n";
			print " ", $key, " |  ";
			for (0..23) {
				my $dow = $_;
				print $table -> {$key} -> {$dow};
				if ($dow > 9) {
					print "   ";
				} else {
					print "  ";
				}
			}
			print "\n";
		}

		print "   |";
		print " " for 0..85;
		print "\n";
		print "\n";
	}
} else {
	die "Error! Please try again later! May be resource forbidden or incorrect login! Maybe login hasn't repos!\n";
  #print "Authentification Error\n";
}
