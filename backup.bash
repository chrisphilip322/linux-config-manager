# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")

cd "$SCRIPTPATH/files"
unset files
declare -a files
while IFS= read -r -u3 -d $'\0' file; do
    target_dir="$(dirname "$file")"
    if [[ -a "$HOME/$target_dir" ]]
    then
        :
    else
        mkdir -p "$HOME/$target_dir"
    fi
    touch "$HOME/$file"
    files+=( "$file" )
done 3< <(find . -type f -print0)
cd $HOME
tar -cf "$SCRIPTPATH/backups/$(date +"%Y%m%dT%H%M%S").tar" "${files[@]}"
