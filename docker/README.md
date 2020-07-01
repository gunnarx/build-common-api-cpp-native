### docker directory

The purpose of this directory is to build a publishable container image.
Projects that want to build on top of this project can then pull the image and
either use the binaries via a container, or perhaps build a new image with
this as the base.

Because we want an image that can be published it's of course most logical
to encode the steps in `Dockerfile` instead of a script.
And at the same time we want to minimize the size of the image and keep only
the binary results and not the source code.  Therefore `Dockerfile` does not
reuse the steps encoded in run_in_docker.sh

(`run_in_docker.sh` remains useful for development where you expect to run it
locally and continue using the container afterwards, including all the source
code remaining in place)

