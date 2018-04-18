# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT="$(readlink -f "$0")"
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH="$(dirname "$SCRIPT")"

cd "$SCRIPTPATH/files"
find . -type f | while read line
do
    target_dir="$(dirname "$line")"
    if [[ -a "$target_dir" ]]
    then
        :
    else
        mkdir -p "$target_dir"
    fi
    cp "$line" "$HOME/$line"
done
