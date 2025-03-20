> [!IMPORTANT]
> We will discontinue maintenance of this Docker image and archive this repository when RedMica 3.2.0 is released, which is scheduled for May 2025. This means that Docker images for RedMica 3.2.0 and later will not be provided.
> 
> Please note that the development of RedMica will continue as usual; we are only discontinuing maintenance of this Docker image.

# RedMica's Dockerfile

This repository develops RedMica's Dockerfile [Docker Hub link](https://hub.docker.com/r/redmica/redmica).  
How to use Docker image: [Description](description.md)

## Add RedMica version

```
$ git clone https://github.com/redmica/redmica_docker.git
$ cd redmica_docker
$ # Add latest RedMica version directory
$ mkdir <new RedMica full version>
$ docker run --rm -w /redmica_docker --volume $PWD:/redmica_docker buildpack-deps /redmica_docker/update.sh <new RedMica full version>
```

## License

This repository is a fork of [docker-library/redmine](https://github.com/docker-library/redmine).  
[docker-library/redmine](https://github.com/docker-library/redmine) is licensed under the [GNU General Public License v2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) (GPL).

## Maintainer

[Far End Technologies Corporation](https://www.farend.co.jp/)
