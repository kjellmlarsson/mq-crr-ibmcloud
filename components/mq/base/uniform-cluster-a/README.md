### Uniform clusters and CRR example

Sample of running an MQ client that connects to queue managers that are part of uniform clusters and use CRR across two regions, Frankfurt and Madrid.

Uniform cluster consists of two QMs, QM1 and QM2. QM1 and QM2 use CRR and are Live in one region at a time.

#### Setup

1. Build the rdqmput and rdqmget binaries as described here: https://github.com/ibm-messaging/mq-rdqm/tree/master/samples
1. Create a truststore that contains the root certificates used for the queue managers and the site hosting the ccdt url. For Github, this is the Sectigo root found here: https://crt.sh/?id=1199354

```/opt/mqm/bin/runmqakm -keydb -create -db key.kdb -pw password -type cms -expire 365 -stash```

```/opt/mqm/bin/runmqakm -cert -add -db key.kdb -label cert-label -file ca.crt -pw password```

1. Modify [mqclient.ini](mqclient.ini) and [run_rdqmput](run_rdqmput) with values for your environment

#### Running the sample

1. ```./run_rdqmput -v 2 -b 20 -m 10 '*ANY_QM' Q1``` will run 20 batches of 10 messages with output verbosity 2 which reports the status of each message
1. Check which of the two live queue managers that is receiving messages. Delete the statefulset for this QM, simulating a failure
1. Confirm that the client reconnects to the other live queue manager and continues putting messages
1. Perform a (planned) switchover, moving the running QMs from one region to the other
1. Verify that the client reconnects to the QMs in the "new" live region
