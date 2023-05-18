grep "IMPORTANT CONTEXT" \
  --exclude-dir .git \
  --exclude-dir log \
  --exclude-dir tmp \
  --exclude-dir storage \
  --exclude-dir node_modules \
  --exclude-dir .context \
  -lr . \
  | sort
