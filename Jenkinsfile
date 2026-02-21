pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  parameters {
    //   Optional: keep for manual overrides, but rules below will force dev for PR/non-main
    choice(name: 'ACTION', choices: ['plan', 'apply'], description: 'Terraform action (apply allowed only on main)')
    string(name: 'AWS_REGION', defaultValue: 'us-east-1', description: 'AWS region')
    booleanParam(name: 'AUTO_APPROVE', defaultValue: false, description: 'Auto-approve apply (only used on main)')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    TF_INPUT         = 'false'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Branch Rules (Mode A)') {
      steps {
        script {
          def isPR = (env.CHANGE_ID?.trim())
          def isMain = (env.BRANCH_NAME == 'main')

          //  Mode A mapping: everything goes to DEV in this pipeline
          env.ENV_NAME = 'dev'
          env.TF_DIR   = "infra/envs/dev"
          env.TFVARS   = "dev.tfvars"
          env.PLAN_FILE = "tfplan-dev.out"

          // Enforce actions
          if (isPR) {
            env.EFFECTIVE_ACTION = 'plan'
            currentBuild.description = "PR-${env.CHANGE_ID} plan (dev)"
          } else if (!isMain) {
            env.EFFECTIVE_ACTION = 'plan'
            currentBuild.description = "${env.BRANCH_NAME} plan (dev)"
          } else {
            // main branch: allow plan or apply (based on parameter)
            env.EFFECTIVE_ACTION = params.ACTION
            currentBuild.description = "main ${env.EFFECTIVE_ACTION} (dev)"
          }

          // Safety: never allow apply off-main even if user selects it
          if (!isMain && env.EFFECTIVE_ACTION == 'apply') {
            error("Apply is blocked on branch '${env.BRANCH_NAME}'. Only 'main' can apply (Mode A).")
          }

          echo "BRANCH_NAME=${env.BRANCH_NAME}, CHANGE_ID=${env.CHANGE_ID}"
          echo "ENV_NAME=${env.ENV_NAME}, EFFECTIVE_ACTION=${env.EFFECTIVE_ACTION}"
          echo "TF_DIR=${env.TF_DIR}, TFVARS=${env.TFVARS}"
        }
      }
    }

    stage('Terraform Init') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arr-lab-aws']]) {
          sh """
            set -e
            cd "${env.TF_DIR}"
            export AWS_DEFAULT_REGION='${params.AWS_REGION}'
            terraform -version
            aws --version || true
            aws sts get-caller-identity
            terraform init -reconfigure
          """
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arr-lab-aws']]) {
          sh """
            set -e
            cd "${env.TF_DIR}"
            export AWS_DEFAULT_REGION='${params.AWS_REGION}'
            terraform validate
            terraform plan -var-file="${env.TFVARS}" -out="${env.PLAN_FILE}"
          """
        }
      }
    }

stage('Create PR to main') {
  when {
    expression { return env.BRANCH_NAME && env.BRANCH_NAME != 'main' }
  }
  steps {
    withCredentials([string(credentialsId: 'github-token', variable: 'GH_TOKEN')]) {
      sh """
        set -e
        export GH_TOKEN='${GH_TOKEN}'

        REPO='arkrud/vpc'

        # Create PR if it doesn't exist
        if gh pr view --repo "\$REPO" --head "${env.BRANCH_NAME}" >/dev/null 2>&1; then
          echo "PR already exists for ${env.BRANCH_NAME}"
        else
          gh pr create --repo "\$REPO" \\
            --base main \\
            --head "${env.BRANCH_NAME}" \\
            --title "Promote ${env.BRANCH_NAME} to main" \\
            --body "Automated PR created by Jenkins after successful Dev plan."
        fi

        # OPTIONAL: enable auto-merge (only merges after required reviews/checks)
        # gh pr merge --repo "\$REPO" --head "${env.BRANCH_NAME}" --auto --merge
      """
    }
  }
}



    stage('Apply (main only)') {
      when { expression { env.EFFECTIVE_ACTION == 'apply' } }
      steps {
        script {
          if (!params.AUTO_APPROVE) {
            input message: "Apply to DEV from main?", ok: "Apply"
          }
        }
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arr-lab-aws']]) {
          sh """
            set -e
            cd "${env.TF_DIR}"
            export AWS_DEFAULT_REGION='${params.AWS_REGION}'
            terraform apply -auto-approve "${env.PLAN_FILE}"
          """
        }
      }
    }
  }
}

stage('Trigger Promote QA') {
  when { branch 'main' }
  steps {
    script {
      def sha = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
      build job: 'Promote', parameters: [
        string(name: 'GIT_REF', value: sha),
        string(name: 'AWS_REGION', value: 'us-east-1'),
        booleanParam(name: 'AUTO_APPROVE', value: false),
        // PROMOTE_TO is a choice param in Promote job; value must match its choices
        [$class: 'StringParameterValue', name: 'PROMOTE_TO', value: 'qa']
      ]
    }
  }
}
