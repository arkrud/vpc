pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  parameters {
    choice(name: 'ENV', choices: ['dev', 'qa', 'prod'], description: 'Target environment')
    choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action')
    string(name: 'AWS_REGION', defaultValue: 'us-east-1', description: 'AWS region')
    booleanParam(name: 'AUTO_APPROVE', defaultValue: false, description: 'Auto-approve apply/destroy (NOT allowed for prod)')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    TF_INPUT         = 'false'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Select Environment') {
      steps {
        script {
          env.TF_DIR    = isUnix() ? "infra/envs/${params.ENV}" : "infra\\envs\\${params.ENV}"
          env.TFVARS    = "${params.ENV}.tfvars"
          env.PLAN_FILE = "tfplan-${params.ENV}.out"
        }
        script {
          echo "TF_DIR=${env.TF_DIR} TFVARS=${env.TFVARS} PLAN_FILE=${env.PLAN_FILE}"
        }
      }
    }

    stage('Terraform Init') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arr-lab-aws']]) {
          script {
            if (isUnix()) {
              sh """
                set -e
                cd "${env.TF_DIR}"
                export AWS_DEFAULT_REGION='${params.AWS_REGION}'
                terraform -version
                aws --version || true
                aws sts get-caller-identity
                terraform init -reconfigure
              """
            } else {
              powershell """
                Set-Location "${env.TF_DIR}"
                $env:AWS_DEFAULT_REGION="${params.AWS_REGION}"
                terraform -version
                aws --version
                aws sts get-caller-identity
                terraform init -reconfigure
              """
            }
          }
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-lab-creds']]) {
          script {
            if (isUnix()) {
              sh """
                set -e
                cd "${env.TF_DIR}"
                export AWS_DEFAULT_REGION='${params.AWS_REGION}'
                terraform validate
                terraform plan -var-file="${env.TFVARS}" -out="${env.PLAN_FILE}"
              """
            } else {
              powershell """
                Set-Location "${env.TF_DIR}"
                $env:AWS_DEFAULT_REGION="${params.AWS_REGION}"
                terraform validate
                terraform plan -var-file="${env.TFVARS}" -out="${env.PLAN_FILE}"
              """
            }
          }
        }
      }
    }

    stage('Approval for Prod') {
      when { expression { params.ENV == 'prod' && (params.ACTION in ['apply','destroy']) } }
      steps {
        script {
          if (params.AUTO_APPROVE) {
            error("AUTO_APPROVE is not allowed for prod. Uncheck AUTO_APPROVE and rerun.")
          }
        }
        input message: "Approve ${params.ACTION} to PROD?", ok: "Approve"
      }
    }

    stage('Terraform Apply / Destroy') {
      when { expression { params.ACTION in ['apply','destroy'] } }
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-lab-creds']]) {
          script {
            def approveFlag = params.AUTO_APPROVE ? "-auto-approve" : ""
            if (params.ACTION == 'apply') {
              if (isUnix()) {
                sh """
                  set -e
                  cd "${env.TF_DIR}"
                  export AWS_DEFAULT_REGION='${params.AWS_REGION}'
                  terraform apply ${approveFlag} "${env.PLAN_FILE}"
                """
              } else {
                powershell """
                  Set-Location "${env.TF_DIR}"
                  $env:AWS_DEFAULT_REGION="${params.AWS_REGION}"
                  terraform apply ${approveFlag} "${env.PLAN_FILE}"
                """
              }
            } else { // destroy
              if (isUnix()) {
                sh """
                  set -e
                  cd "${env.TF_DIR}"
                  export AWS_DEFAULT_REGION='${params.AWS_REGION}'
                  terraform destroy ${approveFlag} -var-file="${env.TFVARS}"
                """
              } else {
                powershell """
                  Set-Location "${env.TF_DIR}"
                  $env:AWS_DEFAULT_REGION="${params.AWS_REGION}"
                  terraform destroy ${approveFlag} -var-file="${env.TFVARS}"
                """
              }
            }
          }
        }
      }
    }
  }
}
