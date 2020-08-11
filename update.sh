#!/usr/bin/env bash
set -Eeuo pipefail

# see https://www.redmine.org/projects/redmine/wiki/redmineinstall
defaultRubyVersion='2.6'
declare -A rubyVersions=(
	#[3.4]='2.4'
)

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

passenger="$(wget -qO- 'https://rubygems.org/api/v1/gems/passenger.json' | sed -r 's/^.*"version":"([^"]+)".*$/\1/')"

dockerfileDirectories=''

for version in "${versions[@]}"; do
	rubyVersion="${rubyVersions[$version]:-$defaultRubyVersion}"
	dockerfileDirectories+="\'$version\', \'$version\/alpine\', \'$version\/passenger\', "
	echo "$version: (ruby $rubyVersion; passenger $passenger)"

	commonSedArgs=(
		-r
		-e 's/%%REDMICA_VERSION%%/'"$version"'/'
		-e 's/%%RUBY_VERSION%%/'"$rubyVersion"'/'
		-e 's/%%REDMICA%%/redmica\/redmica:'"$version"'/'
		-e 's/%%PASSENGER_VERSION%%/'"$passenger"'/'
	)
	alpineSedArgs=()

	# https://github.com/docker-library/redmine/pull/184
	# https://www.redmine.org/issues/22481
	# https://www.redmine.org/issues/30492
	commonSedArgs+=(
		-e '/imagemagick-dev/d'
		-e '/libmagickcore-dev/d'
		-e '/libmagickwand-dev/d'
	)

	cp docker-entrypoint.sh "$version/"
	sed "${commonSedArgs[@]}" Dockerfile-debian.template > "$version/Dockerfile"

	mkdir -p "$version/passenger"
	sed "${commonSedArgs[@]}" Dockerfile-passenger.template > "$version/passenger/Dockerfile"

	mkdir -p "$version/alpine"
	cp docker-entrypoint.sh "$version/alpine/"
	sed -i -e 's/gosu/su-exec/g' "$version/alpine/docker-entrypoint.sh"
	sed "${commonSedArgs[@]}" "${alpineSedArgs[@]}" Dockerfile-alpine.template > "$version/alpine/Dockerfile"
done

sedTestDirectories=(
	-r
	-e 's/%%DOCKERFILE_DIRECTORIES%%/'"$dockerfileDirectories"'/'
)
sed "${sedTestDirectories[@]}" circleci-config.template > ".circleci/config.yml"
