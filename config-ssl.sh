#!/usr/bin/env bash

[ -d ssl -a -f ssl/server.pem ] && exit 0

function die() {
    echo "--- fail"
    exit 1
}

mkdir ssl || die
cd ssl || die

openssl genrsa -out ca-key.pem 4096
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=net-imap-simple"

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

openssl genrsa -out server.pem 4096
openssl req -new -key server.pem -out server.csr -subj "/CN=net-imap-simple" -config openssl.cnf
openssl x509 -req -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server.pem \
    -days 10000 -extensions v3_req -extfile openssl.cnf
