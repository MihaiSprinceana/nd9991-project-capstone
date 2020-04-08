pipeline {
  agent any
  environment {
    EKS = 'EKS-zKxrNmkcHKb7'
    APP = "capstone"
    DOCKER_REGISTRY = '103332013575.dkr.ecr.eu-west-2.amazonaws.com'
    ECRCRED = 'ecr:eu-west-2:Jenkins_Role'
    IMAGE_TAG = "${APP}:${env.BUILD_ID}"
    AWS_REGION = "eu-west-2"
    CRED_ID = "Jenkins_Role"
    currentEnvironment = 'blue'
    newEnvironment = 'green'
  }
  stages {
    stage('Build') {
      steps {
         sh 'echo "Hello World"'
         sh '''
             echo "Multiline shell steps works too"
             ls -lah
         '''
      }
    }

    stage('Lint HTML') {
      steps {
        dir("app/public-html") {
          sh 'tidy -q -e *.html'
        }
      }
    }

    stage('Docker Image') {
      steps {
        //cleanup current user docker credentials
        sh 'rm ~/.dockercfg || true'
        sh 'rm ~/.docker/config.json || true'

        script {
          dir("app") {
            //authentificate to ecr
            def ver_script = $/eval "aws ecr get-login --no-include-email --region=eu-west-2 | sed 's|https://||' " /$
            echo "${ver_script}"

            //build and push the image.  
            docker.withRegistry("https://${DOCKER_REGISTRY}", ECRCRED)
            {
              def image = docker.build("${IMAGE_TAG}")
              image.push()  
            }            
          }
        }
      }
    }

    stage('Check Env') {
      steps {
        withAWS(credentials: "${CRED_ID}", region: "${AWS_REGION}") {
          // check the current active environment to determine the inactive one that will be deployed to
          // fetch the current service configuration
          sh """
            aws eks --region eu-west-2 update-kubeconfig --name ${EKS} --kubeconfig ~/kubeconfig
            current_role="\$(kubectl get services --kubeconfig ~/kubeconfig ${APP}-service --output json | jq -r .spec.selector.role)"
            if [ "\$current_role" = null ]; then
                echo "Unable to determine current environment"
                exit 1
            fi
            echo "\$current_role" >current-environment
          """  
        }
        script {
             // parse the current active backend
          currentEnvironment = readFile('current-environment').trim()
          newEnvironment = currentEnvironment == 'blue' ? 'green' : 'blue'
          // set the build name
          echo "***************************  CURRENT: $currentEnvironment     NEW: ${newEnvironment}  *****************************"

          currentBuild.displayName = newEnvironment.toUpperCase() + ' ' + IMAGE_TAG

          env.TARGET_ROLE = newEnvironment
        }  
        // clean the inactive environment
        withAWS(credentials: "${CRED_ID}", region: 'eu-west-2') {
          sh """
          kubectl --kubeconfig ~/kubeconfig delete --ignore-not-found deployment "${APP}-deployment-\$TARGET_ROLE"
          """ 
        }   
      }
    }

    stage('Deploy') {
      steps {
        dir("infrastructure/kubernetes") {
          withAWS(credentials: "${CRED_ID}", region: "${AWS_REGION}") {
            script {
              sh "./set-docker-repo.sh"

              // deploy new app
              sh "envsubst < deployment.yaml | kubectl --kubeconfig ~/kubeconfig apply -f -"
              // deploy test load balancer
              sh "envsubst < service-test.yaml | kubectl --kubeconfig ~/kubeconfig apply -f -"  
              
            }
          }
        }  
      }
    }

    stage('Verify Staged') {
      environment {
        // verify the deployment through the corresponding test endpoint
        service = "${APP}-test-${newEnvironment}"
      }
      steps {
        withAWS(credentials: "${CRED_ID}", region: "${AWS_REGION}") {
          sh """
            count=0
            while true; do
                endpoint_ip="\$(kubectl get services '${service}' --kubeconfig ~/kubeconfig --output json | jq -r '.status.loadBalancer.ingress[0].hostname')"
                count=\$(expr \$count + 1)
                if curl -m 10 "http://\$endpoint_ip"; then
                    break;
                fi
                if [ "\$count" -gt 30 ]; then
                    echo 'Timeout while waiting for the ${service} endpoint to be ready'
                    exit 1
                fi
                echo "${service} endpoint is not ready, wait 10 seconds..."
                sleep 10
            done
          """
        }
      }
    }

    stage('Switch') {
      steps {
        dir("infrastructure/kubernetes") {
          withAWS(credentials: "${CRED_ID}", region: "${AWS_REGION}") {
            script {
              sh "./set-docker-repo.sh"
              sh "envsubst < service.yaml | kubectl --kubeconfig ~/kubeconfig apply -f -"
            }
          }
        }  
      }
    }

    stage('Verify Prod') {
      environment {
        // verify the production environment is working properly
        service = "${APP}-service"
      }
      steps {
        withAWS(credentials: "${CRED_ID}", region: "${AWS_REGION}") {
          sh """
            count=0
            while true; do
                endpoint_ip="\$(kubectl --kubeconfig ~/kubeconfig get services '${service}' --output json | jq -r '.status.loadBalancer.ingress[0].hostname')"
                count=\$(expr \$count + 1)
                if curl -m 10 "http://\$endpoint_ip"; then
                    break;
                fi
                if [ "\$count" -gt 30 ]; then
                    echo 'Timeout while waiting for the ${service} endpoint to be ready'
                    exit 1
                fi
                echo "${service} endpoint is not ready, wait 10 seconds..."
                sleep 10
            done
          """
        }
      }
    }

    stage('Post-clean') {
      steps {
        sh "rm -f ~/kubeconfig"
      }
    } 
  }
}