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
while read domain; do
    subfinder -d "$domain" -silent | sort -u | dnsx -silent > subdomains/$domain.txt
done < Wildcards.txt

# Crawling targets
echo -e "\033[38;5;75mCrawling targets\033[0m"
if [ -d "targets" ]; then
    echo "Folder 'targets' exists"
    exit 1
else
    mkdir targets
fi
for target in subdomains/*.txt; do
    katana -u "$target" -jc -silent | grep -vE '\.(css|jpg|jpeg|png|svg|img|gif|mp4|flv|pdf|doc|ogv|webm|wmv|webp|mov|mp3|m4a|m4p|ppt|pptx|scss|tif|tiff|ttf|otf|woff|woff2|bmp|ico|eot|htc|swf|rtf)(\?.*)?$' | sort -u | uro > targets/$target.txt
done


