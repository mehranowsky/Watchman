#!/bin/bash
export PATH=$PATH:/usr/local/bin:/root/go/bin

set -euo pipefail
IFS=$'\n\t'

SUB_DIR="SpaceCowboy/subdomains"
URL_DIR="SpaceCowboy/urls"

# Creating root dir
if [ -d "SpaceCowboy" ]; then
    echo "Continue 'SpaceCowboy' hunting..."
else
    mkdir -p "SpaceCowboy"
fi

# Fetching data from hackerone
echo -e "\033[38;5;75mFetching data from hackerone\033[0m"
python3 watchman.py -a
./notification.sh "Fetched data from h1"
sleep 10

# Clean h1_Wildcards.txt (remove * , scheme, path, port)
if [ -f h1_Wildcards.txt ]; then
  sed -E 's/[*]//g; s#^https?://##I; s#/.*$##; s/:[0-9]+$//; s/\.\././g; s/^[.]//; s/[.]$//' h1_Wildcards.txt | grep -aEv '^$|^-' | sort -u > h1_Wildcards.tmp && mv h1_Wildcards.tmp h1_Wildcards.txt
fi

# Clean h1_URLs.txt (remove paths and query strings)
if [ -f h1_URLs.txt ]; then
  sed -E 's/^[[:space:]]+|[[:space:]]+$//g' h1_URLs.txt \
    | sed -E '/^$/d' \
    | sed -E 's#^([^/:]+)(/.*)?$#https://\1#; s#^https?://([^/]+).*#https://\1#I' \
    | sort -u > h1_URLs.tmp && mv h1_URLs.tmp h1_URLs.txt
fi

# Subdomain enumeration
echo -e "\033[38;5;75mSubdomain enumeration\033[0m"
mkdir -p "$SUB_DIR"
./notification.sh "Starts subdomain enumeration..."

while read -r domain <&3; do
    [ -z "$domain" ] && continue
    clean_name=$(echo "$domain" | sed -E 's#^https?://##I;s#/.*$##;s/:[0-9]+$//;s/[*]//g;s/%[0-9A-Fa-f]{2}/_/g;s/-+/_/g;s/^_+/_/;s/_+$//;')
    
    subfinder -d "$domain" -all -silent -t 5 | sort -u > "$SUB_DIR/$clean_name.tmp"

    # Skip empty results
    if [ ! -s "$SUB_DIR/$clean_name.tmp" ]; then
        rm -f "$SUB_DIR/$clean_name.tmp"
        continue
    fi

    dnsx -silent -t 70 -l "$SUB_DIR/$clean_name.tmp" | httpx -silent -t 30 > "$SUB_DIR/$clean_name.txt"
    # If the final output file is empty, remove it
    [ -s "$SUB_DIR/$clean_name.txt" ] || rm -f "$SUB_DIR/$clean_name.txt"

    rm -f "$SUB_DIR/$clean_name.tmp"
    sleep 5
done 3< h1_Wildcards.txt

./notification.sh "Completed subdomain enumeration and starts crawling..."
sleep 10

# Crawling subdomains and h1_URLs
echo -e "\033[38;5;75mCrawling all targets\033[0m"
mkdir -p "$URL_DIR"

crawl_url() {
    local url="$1"
    local file_name
    file_name=$(echo "$url" | sed -E 's#^https?://##I;s#/.*$##;s/:[0-9]+$//;s/[*]//g;s/%[0-9A-Fa-f]{2}/_/g;s/-+/_/g;s/^_+/_/;s/_+$//;')

    echo "$url" | gau 2>/dev/null > "$URL_DIR/$file_name.tmp"
    sleep 2
    echo "$url" | katana -silent -jc 2>/dev/null >> "$URL_DIR/$file_name.tmp"

    grep -aEv '\.(css|jpg|jpeg|png|svg|gif|mp4|pdf|docx?|pptx?|mp3|webp|ico|woff2?|eot|tiff?|mov|avi|swf|rtf)(\?.*)?$' "$URL_DIR/$file_name.tmp" | sort -u | uro > "$URL_DIR/$file_name.txt"

    [ -s "$URL_DIR/$file_name.txt" ] || rm -f "$URL_DIR/$file_name.txt"

    rm -f "$URL_DIR/$file_name.tmp"
    sleep 5
}

# Crawl subdomains
for domain_file in "$SUB_DIR"/*.txt; do
    [ -s "$domain_file" ] || continue
    while read -r subdomain; do
        [ -z "$subdomain" ] && continue
        crawl_url "$subdomain"
    done < "$domain_file"
done

# Crawl h1_URLs (fixed filename)
if [ -f h1_URLs.txt ]; then
    while read -r url; do
        [ -z "$url" ] && continue
        crawl_url "$url"
    done < h1_URLs.txt
fi

./notification.sh "Crawling completed!"
./notification.sh "****End of tasks****"
echo -e "\033[38;5;75mCrawling completed! (Subdomains + Watchman URLs)\033[0m"
