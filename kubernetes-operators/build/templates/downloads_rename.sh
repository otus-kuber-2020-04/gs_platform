for file in *.txt; do
NEWNAME=$(basename $file .txt)
mv -- "$file" "$NEWNAME"
done
