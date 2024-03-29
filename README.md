# Personal
### (But not private. Do whatever you want with any of this)
<br />
<br />


## Import zshrc

```
cp ~/.zshrc ~/.zshrc$(date +%Y%m%d%H%M%S%N).bak ; wget -O- -q "https://github.com/JJenkx/Personal/raw/main/.zshrc" >~/.zshrc ; exec zsh
```


<br />

## Import scripts 

```

scripts='https://raw.githubusercontent.com/JJenkx/Personal/main/.zshrcscripts='https://raw.githubusercontent.com/JJenkx/Personal/main/.zshrc
https://raw.githubusercontent.com/JJenkx/Personal/main/backupplasmadesktop.sh
https://raw.githubusercontent.com/JJenkx/Personal/main/CIDRtoIP.sh
https://raw.githubusercontent.com/JJenkx/Personal/main/convertwebp
https://raw.githubusercontent.com/JJenkx/Personal/main/gclone.sh
https://raw.githubusercontent.com/JJenkx/Personal/main/hwall
https://raw.githubusercontent.com/JJenkx/Personal/main/manx
https://raw.githubusercontent.com/JJenkx/Personal/main/mpv_randomwall
https://raw.githubusercontent.com/JJenkx/Personal/main/mpvhist
https://raw.githubusercontent.com/JJenkx/Personal/main/namekill
https://raw.githubusercontent.com/JJenkx/Personal/main/plex_dl
https://raw.githubusercontent.com/JJenkx/Personal/main/plex_dl_list
https://raw.githubusercontent.com/JJenkx/Personal/main/pw
https://raw.githubusercontent.com/JJenkx/Personal/main/randomplay
https://raw.githubusercontent.com/JJenkx/Personal/main/restoreplasmadesktop.sh
https://raw.githubusercontent.com/JJenkx/Personal/main/searchstackoverflowdatadump.sh
https://raw.githubusercontent.com/JJenkx/Personal/main/searchwikipedia.sh
https://raw.githubusercontent.com/JJenkx/Personal/main/timer
https://raw.githubusercontent.com/JJenkx/Personal/main/tts.sh
https://raw.githubusercontent.com/JJenkx/Personal/main/vwall'
cat<<< "$scripts" | parallel -j 8 wget -O $HOME/.local/scripts/{/} {}

```

<br />


## Get random quotes from deadwood
All
```
printf '\n' ; perl -e 'srand; rand($.) < 1 && ( $line = $_ ) while <>; print $line' /home/jjenkx/Scripts/deadwood.txt | perl -p -e 's/    /\n\n/g' | fold -w 80 -s ; printf '\n'
```
Jane
```
printf '\n' ; perl -e 'srand; rand($.) < 1 && ( $line = $_ ) while <>; print $line' jane.deadwood.txt | perl -p -e 's/    /\n\n/g' | fold -w 80 -s ; printf '\n'
```
<br />
<br />
<br />

## Convert CIDR IP Range to DNSCrypt format for [InviZible Pro](https://github.com/Gedsh/InviZible/)

Generate a list via autonomous system number (ASN) query

Facebook's ASN is AS32934

```
whois -h whois.radb.net -- '-i origin AS32934' | grep -ioP '^route:.*\s\K\d.*' | aggregate6 | perl -0777 -pe 's/\A(?!\n)|\n\Z(?<!\n)/\n/igm' >>Facebook.Instagram.CIDR.Notation.IPs.txt
```

credit https://stackoverflow.com/questions/16986879/bash-script-to-list-all-ips-in-prefix/22499574#22499574 for .sh script
```
chmod +x CIDRtoIP.sh
```
```
cat Facebook.Instagram.CIDR.Notation.IPs.txt | while IFS= read -r line ; do ./CIDRtoIP.sh "$line" >>completely.expanded.single.ips.txt; done
```
```
cat completely.expanded.single.ips.txt | perl -0777 -pe 's/^(\d+\.\d+\.\d+.)(0)(?:\1\d+|\n)+(?<=255)/$1*\n/gim' | perl -0777 -pe 's/(?<!\n)\n(?=\d)/\n\n/gim' >converted.to.dnscrypt.format.txt
```
<br />

The file with the properly formatted schema for "ip-blacklist.txt" will be "converted.to.dnscrypt.format.txt"

<br />

Backup InviZible Pro to a zip file.

<br />

Paste the contents from file "converted.to.dnscrypt.format.txt" into IZBackup.zip/app_data/dnscrypt-proxy/ip-blacklist.txt

<br />

Save zip file

<br />

Restore from zip
