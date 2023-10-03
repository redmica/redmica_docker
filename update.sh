#!/usr/bin/env bash
set -Eeuo pipefail

# see https://www.redmine.org/projects/redmine/wiki/redmineinstall
defaultRubyVersion='3.2'
declare -A rubyVersions=(
)

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

new_versions=("$@")

dockerfileDirectories=''

for version in $new_versions; do
	rubyVersion="${rubyVersions[$version]:-$defaultRubyVersion}"
	dockerfileDirectories+="\'$version\', \'$version\/alpine\'', "
	echo "$version: (ruby $rubyVersion;)"

	commonSedArgs=(
		-r
		-e 's/%%REDMICA_VERSION%%/'"$version"'/'
		-e 's/%%RUBY_VERSION%%/'"$rubyVersion"'/'
		-e 's/%%REDMICA%%/redmica\/redmica:'"$version"'/'
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

	mkdir -p "$version/alpine"
	cp docker-entrypoint.sh "$version/alpine/"
	sed -e 's/gosu/su-exec/g' "$version/alpine/docker-entrypoint.sh" > /tmp/docker-entrypoint.sh
	cp /tmp/docker-entrypoint.sh "$version/alpine/docker-entrypoint.sh"
	sed "${commonSedArgs[@]}" Dockerfile-alpine.template > "$version/alpine/Dockerfile"
done
