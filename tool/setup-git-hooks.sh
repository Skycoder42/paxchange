#!/bin/bash
set -eo pipefail

mkdir -p .git/hooks
echo "#!/bin/bash" > .git/hooks/pre-commit
echo "set -e" >> .git/hooks/pre-commit
echo "exec dart run dart_pre_commit" >> .git/hooks/pre-commit
chmod a+x .git/hooks/pre-commit
