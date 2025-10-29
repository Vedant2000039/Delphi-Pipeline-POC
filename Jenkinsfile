pipeline {
  agent any

  environment {
    NODE_HOME = tool name: 'nodejs'
    PATH = "${NODE_HOME}/bin:${env.PATH}"
    REPO_URL = 'https://github.com/Vedant2000039/Delphi-Pipeline-POC.git'
    // Notification emails (replace)
    DEV_NOTIFY = 'vmulherkar@xtsworld.in'
    QA_NOTIFY  = 'sonarved@gmail.com'
  }

  options {
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps {
        echo "Checking out branch 'dev' by default"
        git branch: 'dev', url: "${env.REPO_URL}"
      }
    }

    stage('Install Dependencies') {
      steps {
        dir('backend') {
          sh 'npm install'
        }
      }
    }

    stage('Unit Tests') {
      steps {
        dir('backend') {
          // your current test is a placeholder
          sh 'npm test'
        }
      }
      post {
        failure {
          mail to: "${DEV_NOTIFY}",
               subject: "CI: Unit Tests FAILED - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
               body: "Unit tests failed. Check console log: ${env.BUILD_URL}"
        }
      }
    }

    stage('Deploy to Test (QA)') {
      steps {
        echo "Deploying to QA (test) environment"
        sh 'chmod +x scripts/deploy.sh || true'
        sh 'bash scripts/deploy.sh qa'
      }
      post {
        failure {
          mail to: "${QA_NOTIFY}",
               subject: "CI: Deploy to QA FAILED - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
               body: "Deploy to QA failed. Check ${env.BUILD_URL}"
        }
      }
    }

    stage('Run Test Cases (QA)') {
      steps {
        echo "Running automated test cases against QA"
        sh 'chmod +x scripts/test_cases.sh || true'
        sh 'bash scripts/test_cases.sh qa'
      }
      post {
        success {
          mail to: "${QA_NOTIFY}",
               subject: "CI: QA Tests PASSED - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
               body: "QA test cases passed. Deployment to test env succeeded for build ${env.BUILD_NUMBER}."
        }
        failure {
          mail to: "${QA_NOTIFY}",
               subject: "CI: QA Tests FAILED - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
               body: "QA test cases failed. Build logs: ${env.BUILD_URL}"
        }
      }
    }

    // Add further stages (UAT / Prod) after this if required
  }

  post {
    always {
      echo "Pipeline finished with status: ${currentBuild.currentResult}"
    }
  }
}
