# Instructions for creating new queue managers

* Based on the @/mq-crr/components/mq/base/singleinstance-qm contents, plan an action that creates a new queue manager in @/mq-crr-ibmcloud/components/mq/base directory.
    * If no name is given for the queue manager, ask the user for one.   
* Make sure to correct the dnsNames and the QueueManager names in the CRs to avoid conflicts. 
* For each Queue Manager added: 
    * Update the @/mq-crr-ibmcloud/components/instana-agent/base/instana-agent.yaml file to make sure the new queue manager is monitored. 
    * Update the @/mq-crr-ibmcloud/components/mq/base/CCDT.json to make sure the new queue manager is available in the CCDT file. Use the external route from the certificate for the queue manager address.
* Present your plan for approval.