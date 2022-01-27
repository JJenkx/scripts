# Personal
### (But not private. Do whatever you want with any of this)
 \ 
\
\
\ 
## Get random quotes from deadwood

printf '\n' ; perl -e 'srand; rand($.) < 1 && ( $line = $_ ) while <>; print $line' deadwood.txt | fold -w 80 -s ; printf '\n'






## Convert CIDR IP Range to dnscrypt format

chmod +x CIDRtoIP.sh

touch completely.expanded.single.ips.txt && cat Facebook.Instagram.CIDR.Notation.IPs.txt Google.CIDR.Notation.IPs.txt | while IFS= read -r line ; do ./CIDRtoIP.sh "$line" >>completely.expanded.single.ips.txt; done

touch converted.to.dnscrypt.format.txt && cat completely.expanded.single.ips.txt | perl -0777 -pe 's/^(\d+\.\d+\.\d+.)(0)(?:\1\d+|\n)+(?<=255)/$1*\n/gim' | perl -0777 -pe 's/(?<!\n)\n(?=\d)/\n\n/gim' > converted.to.dnscrypt.format.txt
