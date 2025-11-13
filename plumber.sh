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
  sed -E 's/[*]//g; s#^https?://##I; s#/.*$##; s/:[0-9]+$//; s/\.\././g; s/^[.]//; s/[.]$//' h1_Wildcards.txt \
    | grep -v '^$' | sort -u > h1_Wildcards.tmp && mv h1_Wildcards.tmp h1_Wildcards.txt
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

while read -r domain; do
    [ -z "$domain" ] && continue
    clean_name=$(echo "$domain" | sed -E 's#^https?://##I;s#/.*$##;s/:[0-9]+$//;s/\*/_/g;s/%[0-9A-Fa-f]{2}/_/g;s/[^A-Za-z0-9._-]/_/g;s/_+/_/g;s/^[-_.]+//;s/[-_.]+$//;')
    subfinder -d "$domain" -all -silent -t 5 | sort -u | dnsx -silent -t 70 | httpx -silent -t 30 > "$SUB_DIR/${clean_name}.txt"
    sleep 5
done < h1_Wildcards.txt
./notification.sh "Completed subdomain enumeration and starts crawling..."
sleep 10

# Crawling subdomains and h1_URLs
echo -e "\033[38;5;75mCrawling all targets\033[0m"
mkdir -p "$URL_DIR"

crawl_url() {
    local url="$1"
    local file_name
    file_name=$(echo "$url" | sed -E 's#^https?://##I; s#/.*$##; s/:[0-9]+$//; s/[*]//g; s/%[0-9A-Fa-f]{2}/_/g; s/^-/_/')
    local temp_file
    temp_file=$(mktemp)

    echo "$url" | gau 2>/dev/null >> "$temp_file"
    sleep 2
    echo "$url" | katana -silent -jc 2>/dev/null >> "$temp_file"

    if grep -vE '\.(css|jpg|jpeg|png|svg|gif|mp4|pdf|docx?|pptx?|mp3|webp|ico|woff2?|eot|tiff?|mov|avi|swf|rtf)(\?.*)?$' "$temp_file" \
        | sort -u | uro > "$URL_DIR/${file_name}.txt" && [ -s "$URL_DIR/${file_name}.txt" ]; then
        :
    else
        rm -f "$URL_DIR/${file_name}.txt"
    fi

    rm -f "$temp_file"
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
