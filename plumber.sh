#!/bin/bash

echo -e "\033[38;5;75mFetching data from hackerone\033[0m"
python3 watchman.py -a

# Cleaning wildcards
cat Wildcards.txt | sed 's|^*||' | sed 's|^.||' | grep -v "\*" > Wildcards.tmp

# Sub enumeration
echo -e "\033[38;5;75mSubdomain enumeration\033[0m"
if [ -d "subdomains" ]; then
    echo "Folder 'subdomains' exists"
    exit 1
else
    mkdir subdomains
fi
while read domain; do subfinder -d $domain -silent | dnsx -silent > subdomains/$domain.txt; done < Wildcards.txt

# Crawling targets
echo -e "\033[38;5;75mCrawling targets\033[0m"
while read domain; do subfinder -d $domain -silent | dnsx -silent > subdomains/$domain.txt; done < Wildcards.txt


