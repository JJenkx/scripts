# Personal

Get random quotes from deadwood

printf '\n' ; perl -e 'srand; rand($.) < 1 && ( $line = $_ ) while <>; print $line' deadwood.txt | fold -w 80 -s ; printf '\n'


# Convert CIDR IP Range to dnscrypt format

