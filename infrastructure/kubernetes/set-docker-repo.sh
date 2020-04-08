set -ex

AWS_ACCOUNT=103332013575
AWS_REGION=eu-west-2
DOCKER_REGISTRY_SERVER=https://${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com
DOCKER_USER=AWS
DOCKER_PASSWORD=`aws ecr get-login --region ${AWS_REGION} --registry-ids ${AWS_ACCOUNT} | cut -d' ' -f6`
kubectl --kubeconfig ~/kubeconfig delete secret aws-ecr || true
kubectl --kubeconfig ~/kubeconfig create secret docker-registry aws-ecr \
--docker-server=$DOCKER_REGISTRY_SERVER \
--docker-username=$DOCKER_USER \
--docker-password=$DOCKER_PASSWORD