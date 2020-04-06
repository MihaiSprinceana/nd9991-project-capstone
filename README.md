# nd9991-project-capstone
Udacity Cloud Devops Nanodegree - Project Capstone

## How to create stacks

Execute: sh create-stack.sh stackName stackConfiguration.yml params.json \
Ex for VPC: ./create-stack.sh CapstoneStackVpc vpc/vpc.yml vpc/vpc-parameters.json \
Ex for Servers: ./create-stack.sh CapstoneStackServers servers/server.yml servers/server-parameters.json

## How to update stacks

Execute: sh update-stack.sh stackName stackConfiguration.yml params.json\
Ex for VPC: ./update-stach.sh CapstoneStackVpc vpc/vpc.yml vpc/vpc-parameters.json \
Ex for Servers: ./update-stack.sh CapstoneStackServers servers/server.yml servers/server-parameters.json

## Notes

Update the params accordincly to your needs.\
Don't forget to update the email in the server-parameters.json and the bucket id ( where sits the app files)


