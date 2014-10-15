#!/bin/sh

if [ "$1" == "update" ]; then
    git submodule foreach "git pull origin gh-pages"
    sh genDocset.sh
    exit 0
fi

RES="mori.docset/Contents/Resources/"
DOC="${RES}Documents/"
IDX="${RES}docSet.dsidx"

### clean all up
rm -rf mori.docset
rm -f mori.tgz

### create directory structure
mkdir -p mori.docset/Contents/Resources/Documents/

### copy files
cp files/icon.png mori.docset/icon.png
cp files/Info.plist mori.docset/Contents/Info.plist

### copy documentation
cp mori/index.html "${DOC}index.html"
cp -r mori/css "${DOC}css"
cp -r mori/js "${DOC}js"

### create sql file
sqlite3 $IDX "CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);"
sqlite3 $IDX "CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);"

### remove mori menu
sed '/<div\ class=\"mori\-nav\">/,/<\/div>/d' "${DOC}index.html" > tmp
mv tmp "${DOC}index.html"

### fill index
grep "h2 id" "${DOC}index.html" | while read -r line; do
    NAME=$(echo $line | sed 's/<h2 id.*>\(.*\)<\/h2>/\1/')
    LINK="index.html#$(echo $line | sed 's/<h2 id=\"\(.*\)\">.*/\1/')"
    sqlite3 $IDX "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('$NAME', 'Category', '$LINK');"
done

sed -n '/id=.collections/,/id=.collection_operations/p' "${DOC}index.html" | grep "h3 id" | while read -r line; do
    NAME=$(echo $line | sed 's/<h3 id=\"\(.*\)\">.*/\1/')
    LINK="index.html#$NAME"
    sqlite3 $IDX "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('$NAME', 'Type', '$LINK');"
done

sed -n '/id=.fundamentals/,/id=.collections/p' "${DOC}index.html" | grep "h3 id" | while read -r line; do
    NAME=$(echo $line | sed 's/<h3 id=\"\(.*\)\">.*/\1/')
    LINK="index.html#$NAME"
    sqlite3 $IDX "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('$NAME', 'Method', '$LINK');"
done

sed -n '/id=.collection_operations/,$ p' "${DOC}index.html" | grep "h3 id" | while read -r line; do
    NAME=$(echo $line | sed 's/<h3 id=\"\(.*\)\">.*/\1/')
    LINK="index.html#$NAME"
    sqlite3 $IDX "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('$NAME', 'Method', '$LINK');"
done

### pack things up
tar --exclude='.DS_Store' -cvzf mori.tgz mori.docset

echo done.
