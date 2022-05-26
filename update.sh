#!/usr/bin/env bash
set -Eeuo pipefail

# see https://www.redmine.org/projects/redmine/wiki/redmineinstall
defaultRubyVersion='3.1'
declare -A rubyVersions=(
  [1.0.2]='2.6'
  [1.1.0]='2.6'
  [1.1.1]='2.6'
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
	if [ "$version" = 1.0.0 ] || [ "$version" = 1.0.1 ] || [ "$version" = 1.0.2 ]; then
		commonSedArgs+=(
			-e '/ghostscript /d'
			-e '\!ImageMagick-6/policy\.xml!d'
		)
		alpineSedArgs+=(
			-e 's/imagemagick/imagemagick6/g'
		)
	else
		commonSedArgs+=(
			-e '/imagemagick-dev/d'
			-e '/libmagickcore-dev/d'
			-e '/libmagickwand-dev/d'
		)
	fi

	mkdir -p "$version"
	cp docker-entrypoint.sh "$version/"
	sed "${commonSedArgs[@]}" Dockerfile-debian.template > "$version/Dockerfile"

	if [ -n "$doPassenger" ]; then
		mkdir -p "$version/passenger"
		sed "${commonSedArgs[@]}" \
			-e 's/%%PASSENGER_VERSION%%/'"$passenger"'/' \
			Dockerfile-passenger.template > "$version/passenger/Dockerfile"
	fi

	mkdir -p "$version/alpine"
	cp docker-entrypoint.sh "$version/alpine/"
	sed -i -e 's/gosu/su-exec/g' "$version/alpine/docker-entrypoint.sh"
	sed "${commonSedArgs[@]}" Dockerfile-alpine.template > "$version/alpine/Dockerfile"
done

sedTestDirectories=(
	-r
	-e 's/%%DOCKERFILE_DIRECTORIES%%/'"$dockerfileDirectories"'/'
)
sed "${sedTestDirectories[@]}" circleci-config.template > ".circleci/config.yml"
