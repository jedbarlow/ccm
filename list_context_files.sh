CONTEXT_MARKER="${CCM_CONTEXT_MARKER:-IMPORTANT CONTEXT}"

SHOW_MARKERS=$1

if [ -z "$SHOW_MARKERS" ]; then
  OPTIONS="-l"
else
  OPTIONS=""
fi

IGNORE_DIRS=".git log logs tmp storage node_modules vendor .context $CCM_IGNORE_DIRS"
EXCLUDE_DIRS=$(for dir in $IGNORE_DIRS; do echo -n "--exclude-dir $dir "; done)

IGNORE_FILES=".envrc .env README README.md $CCM_IGNORE_FILES"
EXCLUDE_FILES=$(for file in $IGNORE_FILES; do echo -n "--exclude $file "; done)

grep "$CONTEXT_MARKER" \
  $EXCLUDE_DIRS \
  $EXCLUDE_FILES \
  $OPTIONS \
  -r . \
  | sort
