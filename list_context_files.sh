# first cli argument
SHOW_MARKERS=$1

if [ -z "$SHOW_MARKERS" ]; then
  OPTIONS="-l"
else
  OPTIONS=""
fi

grep "IMPORTANT CONTEXT" \
  --exclude-dir .git \
  --exclude-dir log \
  --exclude-dir tmp \
  --exclude-dir storage \
  --exclude-dir node_modules \
  --exclude-dir .context \
  $OPTIONS \
  -r . \
  | sort
