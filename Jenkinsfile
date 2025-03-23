pipeline {
    agent any

    tools {
        terraform 'Terraform'
        ansible 'Ansible'
    }

    environment {
        TF_VAR_region = 'us-east-1'
        TF_VAR_key_name = 'keypair-01'
        TF_IN_AUTOMATION = 'true'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        ANSIBLE_REMOTE_USER = 'ubuntu'
       
    }

    stages {

        stage('User Input - Create or Destroy?') {
            steps {
                script {
                    def infraAction = input message: 'Create or Destroy Infrastructure?', parameters: [
                        choice(name: 'INFRA_ACTION', choices: ['Create', 'Destroy'], description: 'Select whether to create or destroy infrastructure.')
                    ]
                    env.INFRA_ACTION = infraAction
                }
            }
        }

        stage('User Input - Clone Repository?') {
            when {
                expression { return env.INFRA_ACTION == 'Create' }
            }
            steps {
                script {
                    def cloneInput = input message: 'Clone Repository?', parameters: [
                        choice(name: 'CLONE', choices: ['Yes', 'No'], description: 'Do you want to clone the repository?')
                    ]
                    env.CLONE_REPOSITORY = cloneInput
                }
            }
        }

        stage('Clone Repository') {
            when {
                expression { return env.INFRA_ACTION == 'Create' && env.CLONE_REPOSITORY == 'Yes' }
            }
            steps {
                echo "Cloning the repository..."
                sh 'git clone https://github.com/adilnawaz54/one-click-infra.git'
            }
        }

        stage('Terraform Init') {
            when {
                expression { return env.INFRA_ACTION == 'Create' }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'es-aws-credential']]) {
                    dir('one-click-infra/elasticsearch-tf') {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform fmt') {
            when {
                expression { return env.INFRA_ACTION == 'Create' }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'es-aws-credential']]) {
                    dir('one-click-infra/elasticsearch-tf') {
                        sh 'terraform fmt '
                    }
                }
            }
        }

        stage('Terraform Validate') {
            when {
                expression { return env.INFRA_ACTION == 'Create' }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'es-aws-credential']]) {
                    dir('one-click-infra/elasticsearch-tf') {
                        sh 'terraform validate'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { return env.INFRA_ACTION == 'Create' }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'es-aws-credential']]) {
                    dir('one-click-infra/elasticsearch-tf') {
                        sh 'terraform plan'
                    }
                }
            }
        }

        stage('User Input - Confirm Terraform Apply?') {
            when {
                expression { return env.INFRA_ACTION == 'Create' }
            }
            steps {
                script {
                    def applyConfirm = input message: 'Confirm Terraform Apply?', parameters: [
                        choice(name: 'APPLY_CONFIRM', choices: ['Yes', 'No'], description: 'Do you want to proceed with Terraform apply?')
                    ]
                    env.APPLY_CONFIRM = applyConfirm
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { return env.INFRA_ACTION == 'Create' && env.APPLY_CONFIRM == 'Yes' }
            }
            steps {
                echo "You have chosen to apply the Terraform changes."
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'es-aws-credential']]) {
                    dir('one-click-infra/elasticsearch-tf') {
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Run Ansible Playbook via Bastion Host') {
            when {
                expression { return env.INFRA_ACTION == 'Create' && env.APPLY_CONFIRM == 'Yes' }
            }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'keypair-01', keyFileVariable: 'SSH_PRIVATE_KEY')]) {
                    script {
                        sh '''
                            echo "Fetching bastion host ip for proxy from dynamic inventory..."
                            BASTION_PUBLIC_IP=$(ansible-inventory -i one-click-infra/elasticsearch-roles/aws_ec2.yml --list | jq -r '._meta.hostvars[._Bastion_server.hosts[0]].public_ip_address')

                            cd one-click-infra/elasticsearch-roles
                            echo "Setting ansible_ssh_common_args dynamically..."
                            export ANSIBLE_SSH_COMMON_ARGS="-o ProxyCommand='ssh -W %h:22 -i $SSH_PRIVATE_KEY ubuntu@$BASTION_PUBLIC_IP -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'"

                            echo "Running Ansible playbook on elasticsearch-server-0 via bastion host..."
                            ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_SSH_ARGS='-o ForwardAgent=yes -o ConnectTimeout=60' ansible-playbook -i aws_ec2.yml playbook.yml --private-key=$SSH_PRIVATE_KEY -u ubuntu
                            cd ../..
                        '''
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { return env.INFRA_ACTION == 'Destroy' }
            }
            steps {
                echo "You have chosen to destroy the Terraform infrastructure."
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'es-aws-credential']]) {
                    dir('one-click-infra/elasticsearch-tf') {
                        sh 'terraform destroy -auto-approve'
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed.'
            slackSend (
                teamDomain: 'elasticsearch-infra-demo',
                tokenCredentialId: 'slack',
                channel: '#elasticsearch-infra-notification-demo',
                message: "Pipeline completed. Status: ${currentBuild.result}"
            )
            mail to: 'adilnawaz54@gmail.com', subject: "Jenkins Pipeline Status: ${currentBuild.result}", body: """
            Pipeline execution completed.
            Status: ${currentBuild.result}
            Build URL: ${BUILD_URL}
            """
        }
        success {
            echo 'Pipeline executed successfully!'
            slackSend (
                teamDomain: 'elasticsearch-infra-demo',
                tokenCredentialId: 'slack',
                channel: '#elasticsearch-infra-notification-demo',
                message: "Pipeline succeeded. Build URL: ${BUILD_URL}"
            )
            mail to: 'adilnawaz54@gmail.com', subject: "Jenkins Pipeline Success", body: "Pipeline executed successfully! Build URL: ${BUILD_URL}"
        }
        failure {
            echo 'Pipeline failed.'
            slackSend (
                teamDomain: 'elasticsearch-infra-demo',
                tokenCredentialId: 'slack',
                channel: '#elasticsearch-infra-notification-demo',
                message: "Pipeline failed. Build URL: ${BUILD_URL}"
            )
            mail to: 'adilnawaz54@gmail.com', subject: "Jenkins Pipeline Failure", body: "Pipeline failed. Build URL: ${BUILD_URL}"
        }
        aborted {
            echo 'Pipeline was manually aborted.'
            slackSend (
                teamDomain: 'elasticsearch-infra-demo',
                tokenCredentialId: 'slack',
                channel: '#elasticsearch-infra-notification-demo',
                message: "Pipeline aborted. Build URL: ${BUILD_URL}"
            )
            mail to: 'adilnawaz54@gmail.com', subject: "Jenkins Pipeline Aborted", body: "Pipeline was manually aborted. Build URL: ${BUILD_URL}"
        }
    }
}
