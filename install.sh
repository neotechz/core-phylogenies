docker build --file assets/core-phylogenies.Dockerfile --tag neotechz/core-phylogenies:1.0 .
docker pull fmalmeida/keggdecoder@sha256:72862a7dfec262dcf4716b7d6b65110aad6b77ae86bffccb5c8ecc86ce432ae6

mkdir -p data
mkdir -p results
mkdir -p logs