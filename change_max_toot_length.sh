#!/bin/bash

echoerr() { echo "$@" 1>&2; }

if [[ "$#" -ne 2 ]]; then
  if [[ ${1} != "-h" ]] && [[ ${1} != "help" ]]; then
    echoerr "Incorrect usage of the script."
  fi
  cat << EOF
usage: $0 mastodon_dir desired_length

mastodon_dir - directory, where your Mastodon instance is located
desired_length - desired max length of a toot, has to be an integer greater than 0
EOF
  if [[ ${1} != "-h" ]] && [[ ${1} != "help" ]]; then
    exit 2
  fi
  exit 0
fi

if [[ ! -d $1 ]]; then
  echoerr "Directory \"$1\" does not exist in the filesystem."
  exit 3
fi

DIRECTORY=$1

if ! cd "$DIRECTORY/app"; then
  echoerr "Could not enter directory $DIRECTORY"
  exit 4
fi

if [[ ! -f "javascript/mastodon/features/compose/components/compose_form.js" ]]; then
  echoerr "Are you sure that $DIRECTORY is a correct Mastodon directory? I can't find compose_form.js file where it's supposed to be."
  exit 5
elif [[ ! -f "validators/status_length_validator.rb" ]]; then
  echoerr "Are you sure that $DIRECTORY is a correct Mastodon directory? I can't find status_length_validator.rb file where it's supposed to be."
  exit 6
elif [[ ! -f "serializers/rest/instance_serializer.rb" ]]; then
  echoerr "Are you sure that $DIRECTORY is a correct Mastodon directory? I can't find instance_serializer.rb file where it's supposed to be."
  exit 7
fi

if ! [[ $2 =~ ^[0-9]+$ ]] || [[ $2 -eq 0 ]]; then
  echoerr "\"$2\" is not a signless integer greater than 0"
  exit 2
fi

LENGTH=$2

if grep -q "$LENGTH" javascript/mastodon/features/compose/components/compose_form.js &&
   grep -q "$LENGTH" validators/status_length_validator.rb; then
  echo "No changes needed, max toot length of $LENGTH already set in required files."
else
  if ! sed -i "s/500/$LENGTH/g" javascript/mastodon/features/compose/components/compose_form.js ||
     ! sed -i "s/500/$LENGTH/g" validators/status_length_validator.rb ||
     ! sed -i 's/:registrations/:registrations, :max_toot_chars /g' serializers/rest/instance_serializer.rb ||
     ! sed -i "s/private/def max_toot_chars\n    $LENGTH\n  end\n\n  private/g" serializers/rest/instance_serializer.rb;
  then
    echoerr "Script was unable to make required changes. Instance might be in unstable state now."
    exit 8
  fi
  
  if ! bundle exec rails assets:precompile; then
    echoerr "Assets precompilation failed."
    exit 9
  else
    echo "Assets precompiled successfully."
  fi
  
fi

exit 0
