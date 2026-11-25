
pipeline {

    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['CREATE', 'DESTROY'],
            description: 'Choose infrastructure action'
        )
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Validate') {
            when {
                expression { params.ACTION == 'CREATE' }
            }
            steps {
                dir('terraform') {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'CREATE' }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key',
                           variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key',
                           variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        sh 'terraform plan'
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'CREATE' }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key',
                           variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key',
                           variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        sh 'terraform apply -auto-approve'

                        script {
                            env.EC2_IP = sh(
                                script: 'terraform output -raw public_ip',
                                returnStdout: true
                            ).trim()
                        }
                    }
                }
            }
        }

        stage('Ansible Deployment') {
            when {
                expression { params.ACTION == 'CREATE' }
            }
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh '''
                      sleep 30

                      ANSIBLE_HOST_KEY_CHECKING=False \
                      ansible-playbook \
                      -i "${EC2_IP}," \
                      ansible/playbook.yml \
                      -u ubuntu
                    '''
                }
            }
        }

        stage('Verify Website') {
            when {
                expression { params.ACTION == 'CREATE' }
            }
            steps {
                sh '''
                  for i in $(seq 1 12); do
                    if curl -fsS "http://${EC2_IP}"; then
                      echo "Website deployment successful!"
                      exit 0
                    fi
                    sleep 10
                  done

                  echo "Website verification failed"
                  exit 1
                '''
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'DESTROY' }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key',
                           variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key',
                           variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        sh 'terraform destroy -auto-approve'
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check the Jenkins console output.'
        }
    }
}
