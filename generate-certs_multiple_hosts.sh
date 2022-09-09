#!/usr/bin/env bash
#########################################################################
# Refered to 
#  1. https://www.laub-home.de/wiki/Eclipse_Mosquitto_Secure_MQTT_Broker_Docker_Installation
#  2. https://stackoverflow.com/questions/33494750/self-signed-certificate-for-public-and-private-ip-tomcat-7
# A script to create the self-signed TLS certificate
#########################################################################
#Set the language
export LANG="en_US.UTF-8"
#Load the Paths
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# set the variables --> Please change the following paramters accordingly
COUTRY_CODE=CN
STATE_NAME=Shanghai
CITY_NAME=Shanghai
ORG_NAME=testorg
COMM_NAME=testname

DNS1=dns_1.y.z
DNS2=dns_2.y.z
PUBLIC_IP=0.0.0.0

cat > "./mycert.cnf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]
countryName = Country Name (2 letter code)
countryName_default = $COUTRY_CODE
stateOrProvinceName = State or Province Name (full name)
stateOrProvinceName_default = $STATE_NAME
localityName = Locality Name (eg, city)
localityName_default = $CITY_NAME
organizationalUnitName  = Organizational Unit Name (eg, section)
organizationalUnitName_default  = $ORG_NAME
commonName = CommonName (eg, example.com)
commonName_default = $COMM_NAME
commonName_max  = 64

[ v3_req ]
# Extensions to add to a certificate request
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DNS1
DNS.2 = $DNS2
IP.1 = $PUBLIC_IP
IP.2 = 192.168.1.100
IP.3 = 172.17.0.1
IP.4 = 172.18.0.1
IP.5 = 172.19.0.1

EOF

# Just change to your belongings
COMPOSE_PROJECT_DIR="/opt/mosquitto"

# Optional: Remove the older certificates
rm "$COMPOSE_PROJECT_DIR/certs/ca*.*"
rm "$COMPOSE_PROJECT_DIR/certs/server*.*"
rm "$COMPOSE_PROJECT_DIR/certs/client*.*"
rm "$COMPOSE_PROJECT_DIR/data/mosquitto/conf/certs/*.*"

EXT_CNF_FILE="./mycert.cnf"

SUBJECT_CA="/C=$COUTRY_CODE/ST=$STATE_NAME/L=$CITY_NAME/O=$ORG_NAME/OU=CA"
SUBJECT_SERVER="/C=$COUTRY_CODE/ST=$STATE_NAME/L=$CITY_NAME/O=$ORG_NAME/OU=Server"
SUBJECT_CLIENT="/C=$COUTRY_CODE/ST=$STATE_NAME/L=$CITY_NAME/O=$ORG_NAME/OU=Client"

### Do the stuff
function generate_CA () {
   echo "$SUBJECT_CA"
   openssl req -x509 -nodes -sha256 \
			-newkey rsa:2048 \
			-subj "$SUBJECT_CA"  \
			-days 3650 \
			-keyout $COMPOSE_PROJECT_DIR/certs/ca.key \
			-out $COMPOSE_PROJECT_DIR/certs/ca.crt

	# (Optional) Verify the certificate.
	openssl x509 -in "$COMPOSE_PROJECT_DIR/certs/ca.crt" -noout -text
}

function generate_server () {
   echo "$SUBJECT_SERVER"
   openssl req -nodes -sha256 -new \
			-subj "$SUBJECT_SERVER" \
			-keyout $COMPOSE_PROJECT_DIR/certs/server.key \
			-out $COMPOSE_PROJECT_DIR/certs/server.csr \
			-config $EXT_CNF_FILE

   openssl x509 -req -sha256 \
			-in $COMPOSE_PROJECT_DIR/certs/server.csr \
			-CA $COMPOSE_PROJECT_DIR/certs/ca.crt \
			-CAkey $COMPOSE_PROJECT_DIR/certs/ca.key \
			-CAcreateserial \
			-days 3650 \
			-extensions v3_req \
			-extfile $EXT_CNF_FILE \
			-out $COMPOSE_PROJECT_DIR/certs/server.crt

	# (Optional) Verify the certificate.
	openssl x509 -in "$COMPOSE_PROJECT_DIR/certs/server.crt" -noout -text

}

function generate_client () {
   echo "$SUBJECT_CLIENT"
   openssl req -new -nodes -sha256 \
			-subj "$SUBJECT_CLIENT" \
			-out $COMPOSE_PROJECT_DIR/certs/client.csr \
			-keyout $COMPOSE_PROJECT_DIR/certs/client.key \
			-config $EXT_CNF_FILE

   openssl x509 -req -sha256 \
			-in $COMPOSE_PROJECT_DIR/certs/client.csr \
			-CA $COMPOSE_PROJECT_DIR/certs/ca.crt \
			-CAkey $COMPOSE_PROJECT_DIR/certs/ca.key \
			-CAcreateserial \
			-days 3650 \
			-extensions v3_req \
			-extfile $EXT_CNF_FILE \
			-out $COMPOSE_PROJECT_DIR/certs/client.crt

	# (Optional) Verify the certificate.
	openssl x509 -in "$COMPOSE_PROJECT_DIR/certs/client.crt" -noout -text
}

function copy_keys_to_broker () {
   cp $COMPOSE_PROJECT_DIR/certs/ca.crt $COMPOSE_PROJECT_DIR/data/mosquitto/conf/certs/
   cp $COMPOSE_PROJECT_DIR/certs/server.crt $COMPOSE_PROJECT_DIR/data/mosquitto/conf/certs/
   cp $COMPOSE_PROJECT_DIR/certs/server.key $COMPOSE_PROJECT_DIR/data/mosquitto/conf/certs/
}

generate_CA
generate_server
generate_client
copy_keys_to_broker
