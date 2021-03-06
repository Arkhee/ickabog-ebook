#!/bin/bash

mkdir -p html

LC="/fr" # empty for english
PUP=/root/go/bin/pup
LANG=$(wget --quiet https://www.theickabog.com$LC/read-the-story/ -O- | $PUP 'html attr{lang}')
HTML_FILE=ickabog.html
MAIN_TITLE=$(wget --quiet https://www.theickabog.com$LC/read-the-story/ -O- | $PUP 'ul.chapters__list a json{}' | jq -r '[.[] | {url: .href, chapter: .children[0].children[0].children[0].children[0].text, title: .children[0].children[0].children[0].children[1].text}] | sort_by(.chapter) | .[]|[.chapter, .title, .url] | @tsv' | grep $' 2\t' | while IFS=$'\t' read -r chapter title url; do echo "$title"; done)
OUTPUT_DIR=out

mkdir -p $OUTPUT_DIR

echo "<html><head><title>$MAIN_TITLE</title></head><body>" > "$HTML_FILE"

function download_chapter() {
	[[ $2 =~ 1$ ]] && MAIN_TITLE=$3
    URL=$( [[ $1 =~ ^http ]] && echo "$1" || echo "https://www.theickabog.com$1" )
    [ -s "html/$2.html" ] || wget --quiet "$URL" -O "html/$2.html"
    echo "<h2>$3</h2>" >> "$HTML_FILE"
    cat "html/$2.html" | $PUP 'article div.row:nth-child(2) div.entry-content' >> "$HTML_FILE"
}

wget --quiet https://www.theickabog.com$LC/read-the-story/ -O- | $PUP 'ul.chapters__list a json{}' | jq -r '[.[] | {url: .href, chapter: .children[0].children[0].children[0].children[0].text, title: .children[0].children[0].children[0].children[1].text}] | sort_by(.chapter | match("[0-9]+$")) | .[]|[.chapter, .title, .url] | @tsv' | while IFS=$'\t' read -r chapter title url; do download_chapter "$url" "$chapter" "$title"; done

echo "</body></html>" >> "$HTML_FILE"

#pandoc --from=html --to=pdf \
#    --output=ickabog1.pdf \
#    --metadata title="The Ickabog" \
#    --metadata author="J.K Rowling" \
#    --pdf-engine=xelatex \
#    --dpi=300 \
#    -V book \
#    -V lang=en-US \
#    -V geometry=margin=1.5cm \
#    "$HTML_FILE"

#pdftk cover.pdf ickabog1.pdf cat output ickabog.pdf

echo "<dc:title id=\"epub-title-1\">$MAIN_TITLE</dc:title>" > metadata.xml
echo "<dc:date>$(date -I)</dc:date>" >> metadata.xml
echo "<dc:lang>$LANG</dc:lang>" >> metadata.xml
echo "<dc:creator id="epub-creator-1" opf:role="aut">J.K Rowling</dc:creator>" >> metadata.xml

pandoc --from=html --to=epub \
    --output="$OUTPUT_DIR/ickabog.epub" \
    --epub-metadata=metadata.xml \
    --epub-cover-image=cover.jpg \
	--epub-chapter-level=2 \
    --metadata title="$MAIN_TITLE" \
    "$HTML_FILE"

XDG_RUNTIME_DIR=/tmp/runtime-root ebook-convert out/ickabog.epub out/ickabog.mobi > /dev/null

#pandoc --from=html --to=pdf \
#    -V fontsize=18pt \
#    --output=ickabog2.pdf \
#    --metadata title="The Ickabog" \
#    --metadata author="J.K Rowling" \
#    --pdf-engine=context \
#    -V margin-left=0cm \
#    -V margin-right=0cm \
#    -V margin-top=0cm \
#    -V margin-bottom=0cm \
#    -V geometry=margin=0cm \
#    -V lang=en-US \
#    "$HTML_FILE"

#pdftk cover.pdf ickabog2.pdf cat output ickabog-large.pdf
