#!/bin/bash

IFS=$'\n\t'

if [ -d "subdomains" ]; then
    echo "Folder 'subdomains' exists"
    exit 1
else
    mkdir subdomains
fi

echo -e "\033[38;5;75mFetching data from hackerone\033[0m"
python3 watchman.py -a
sleep 10

# Wildcards -> Wildcards.tmp (remove * , scheme, path, port)
if [ -f Wildcards.txt ]; then
  sed -E 's/[*]//g; s#^https?://##I; s#/.*$##; s/:[0-9]+$//; s/\.\././g; s/^[.]//; s/[.]$//' Wildcards.txt \
    | grep -v '^$' | sort -u > Wildcards.tmp && mv Wildcards.tmp Wildcards.txt
fi

# Clean URLs.txt - remove paths and query strings
if [ -f URLs.txt ]; then
  sed -E 's/^[[:space:]]+|[[:space:]]+$//g' URLs.txt \
    | sed -E '/^$/d' \
    | sed -E 's#^([^/:]+)(/.*)?$#https://\1#; s#^https?://([^/]+).*#https://\1#I' \
    | sort -u > URLs.tmp && mv URLs.tmp URLs.txt
fi

# Subdomain enumeration
echo -e "\033[38;5;75mSubdomain enumeration\033[0m"
if [ -d "subdomains" ]; then
    echo "Folder 'subdomains' exists"
    exit 1
else
    mkdir subdomains
fi

while read domain; do
    subfinder -d "$domain" -silent | sort -u | dnsx -silent > "subdomains/$domain.txt"
    sleep 5
done < Wildcards.txt

sleep 10

# Clean subdomains - remove paths and query strings
echo -e "\033[38;5;75mCleaning subdomains\033[0m"
for domain_file in subdomains/*.txt; do
    sed -i.bak 's|\(https\?://[^/]*\).*|\1|' "$domain_file"
    sort -u "$domain_file" -o "$domain_file"
    rm -f "$domain_file.bak"
done

# Crawling each individual subdomain + watchman URLs
echo -e "\033[38;5;75mCrawling all targets\033[0m"
if [ -d "targets" ]; then
    echo "Folder 'targets' exists"
    exit 1
else
    mkdir targets
fi

# Function to crawl a single URL
crawl_url() {
    local url="$1"
    local safe_name=$(echo "$url" | sed 's|https\?://||' | sed 's|[/:]|_|g')
    local temp_file=$(mktemp)
    
    # Passive crawling with gau
    echo "$url" | gau --threads 10 2>/dev/null >> "$temp_file"
    sleep 2
    
    # Active crawling with katana
    echo "$url" | katana -silent -jc 2>/dev/null >> "$temp_file"
    
    # Process combined results
    if cat "$temp_file" | \
       grep -vE '\.(css|jpg|jpeg|png|svg|img|gif|mp4|flv|pdf|doc|ogv|webm|wmv|webp|mov|mp3|m4a|m4p|ppt|pptx|scss|tif|tiff|ttf|otf|woff|woff2|bmp|ico|eot|htc|swf|rtf)(\?.*)?$' | \
       sort -u | uro > "targets/${safe_name}.txt" && [ -s "targets/${safe_name}.txt" ]; then
        echo "✓ Crawled: $url"
    else
        rm -f "targets/${safe_name}.txt"
        echo "✗ No results: $url"
    fi
    
    rm -f "$temp_file"
    sleep 5
}

# Crawl subdomains from subfinder
for domain_file in subdomains/*.txt; do
    while read subdomain; do
        [ -z "$subdomain" ] && continue
        crawl_url "$subdomain"
    done < "$domain_file"
done

# Crawl URLs from watchman.py
while read url; do
    [ -z "$url" ] && continue
    crawl_url "$url"
done < URLs_cleaned.txt

echo -e "\033[38;5;75mCrawling completed! (Subdomains + Watchman URLs)\033[0m"