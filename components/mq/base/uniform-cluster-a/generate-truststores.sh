#!/bin/bash

# Use the MQ "ibmcloudtrust" truststore in p12 format as a starting point and add the Usertrust / Sectigo certificate to that. 
# Create another truststore in CMS format based on the p12 truststore. Create a JKS truststore for MQ explorer
# MQ uses p12 truststore for outgoing https traffic and CMS truststore for QM traffic

TRUSTSTORE_NAME=truststore
PASSWORD=password

TRUSTSTORE_P12=truststores/p12-$TRUSTSTORE_NAME.p12
TRUSTSTORE_CMS=truststores/CMS-$TRUSTSTORE_NAME.kdb
TRUSTSTORE_JKS=truststores/jks-$TRUSTSTORE_NAME.jks

# Delete existing truststores and stash files. 
rm -rf truststores/
mkdir truststores

# Create a new truststore in p12 format using the default trust from ibm cloud
/opt/mqm/bin/runmqakm -keydb -create -db $TRUSTSTORE_P12 -pw $PASSWORD -stash -type pkcs12 -populate -ibmcloudtrust -expire 365

# Add Sectigo certificates
curl -s https://crt.sh/?d=1199354 > /tmp/usertrust.pem
/opt/mqm/bin/runmqakm -cert -add -db $TRUSTSTORE_P12 -label "USERTrust RSA Certification Authority" -file /tmp/usertrust.pem -pw $PASSWORD

curl -s https://crt.sh/?d=1720081 > /tmp/comodo.pem
/opt/mqm/bin/runmqakm -cert -add -db $TRUSTSTORE_P12 -label "COMODO RSA Certification Authority" -file /tmp/comodo.pem -pw $PASSWORD

/opt/mqm/bin/runmqakm -cert -list -db $TRUSTSTORE_P12 -pw $PASSWORD

# Create a CMS truststore based on the p12 truststore.
/opt/mqm/bin/runmqakm -keydb -create -db $TRUSTSTORE_CMS -pw $PASSWORD -type cms -expire 365 -stash
/opt/mqm/bin/runmqakm -cert -import -file $TRUSTSTORE_P12 -pw $PASSWORD -type pkcs12 -target $TRUSTSTORE_CMS -target_stashed -target_type cms

/opt/mqm/bin/runmqakm -cert -list -db $TRUSTSTORE_CMS -pw $PASSWORD

# Create a JKS keystore based on the p12 truststore
keytool -importkeystore -srckeystore $TRUSTSTORE_P12 -srcstoretype pkcs12 -destkeystore $TRUSTSTORE_JKS -storepass $PASSWORD -srcstorepass $PASSWORD -deststorepass $PASSWORD

# Write all the CA certificates to a text file.
openssl pkcs12 -in $TRUSTSTORE_P12 -noenc -password pass:$PASSWORD | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > truststores/ca.crt