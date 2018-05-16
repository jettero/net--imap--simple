#!/usr/bin/env bash

function die() {
    echo "--- fail"
    exit 1
}

d="$(realpath "$(dirname "$0")")"
cd "$d"

[ -d ssl ] || mkdir ssl
cd ssl || die

[ -f ca-key.pem ] || openssl genrsa -out ca-key.pem 4096
[ -f ca.pem ] || openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=net-imap-simple"

if [ ! -f openssl.cnf ]; then
cat > openssl.cnf << EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1
EOF
fi

[ -f server.key ] || openssl genrsa -out server.key 4096
[ -f server.csr ] || openssl req -new -key server.key -out server.csr \
    -subj "/CN=net-imap-simple" -config openssl.cnf
[ -f server.crt ] || openssl x509 -req -in server.csr -CA ca.pem -CAkey ca-key.pem \
    -CAcreateserial -out server.crt -days 10000 -extensions v3_req -extfile openssl.cnf

# added later... can't really use the entropy of the travis dockers (there isn't any)
cd "$d"
tar -jcvvf ssl.tar.xz ssl
travis encrypt-file ssl.tar.xz ssl.tar.xz.enc --no-interactive
rm -rvf ssl.tar.xz ssl
