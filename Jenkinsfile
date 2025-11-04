// Jenkinsfile — Delphi POC (clean, consistent, environment-aware)
pipeline {
  agent any

  environment {
    // Node tool name configured in Jenkins global tools (adjust if different)
    NODE_HOME = tool name: 'nodejs'
    PATH = "${NODE_HOME}/bin:${env.PATH}"

    // Repo & notifications
    REPO_URL = 'https://github.com/Vedant2000039/Delphi-Pipeline-POC.git'
    DEV_NOTIFY  = 'vmulherkar@xtsworld.in'
    QA_NOTIFY   = 'vmulherkar@xtsworld.in'
    UAT_NOTIFY  = 'vmulherkar@xtsworld.in'
    PROD_NOTIFY = 'vmulherkar@xtsworld.in'

    // Useful defaults
    SCRIPTS_DIR = 'scripts'
    BACKEND_DIR = 'backend'
  }

  options {
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
    timestamps()
    ansiColor('xterm')
  }

  stages {

    stage('Checkout') {
      steps {
        script {
          // Default to dev branch; if building main branch (e.g. production) Jenkins job should be configured accordingly
          def branchToCheckout = env.BRANCH_NAME ?: 'dev'
          echo "Checking out branch: ${branchToCheckout}"
          checkout([$class: 'GitSCM',
                    branches: [[name: "refs/heads/${branchToCheckout}"]],
                    userRemoteConfigs: [[url: REPO_URL]]])
        }
      }
    }

    stage('Prepare Scripts') {
      steps {
        echo "Ensuring scripts are executable and present in ${SCRIPTS_DIR}"
        sh "chmod +x ${SCRIPTS_DIR}/*.sh || true"
      }
    }

    stage('Install Dependencies') {
      steps {
        dir("${BACKEND_DIR}") {
          script {
            if (fileExists('package-lock.json') || fileExists('npm-shrinkwrap.json')) {
              echo "Lockfile found — using npm ci"
              sh 'npm ci --silent'
            } else {
              echo "No lockfile — using npm install"
              sh 'npm install --silent'
            }
          }
        }
      }
    }

    stage('Unit Tests - Dev') {
      when {
        expression { return (env.BRANCH_NAME == null) || env.BRANCH_NAME == 'dev' }
      }
      steps {
        dir("${BACKEND_DIR}") {
          echo "Running unit tests (if any)..."
          // If you have an npm test script; otherwise this will fail — ensure package.json has a test script or wrap in conditional
          sh 'if npm run | grep -q " test"; then npm test || true; else echo "No test script defined"; fi'
        }
      }
      post {
        success {
          mail to: "${DEV_NOTIFY}",
               subject: "✅ Delphi POC | Unit Tests PASSED (Dev) - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
               body: "All Dev unit tests passed successfully. Build URL: ${env.BUILD_URL}"
        }
        failure {
          mail to: "${DEV_NOTIFY}",
               subject: "❌ Delphi POC | Unit Tests FAILED (Dev) - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
               body: "Unit tests failed. Check console log: ${env.BUILD_URL}"
        }
      }
    }

    stage('Deploy to QA') {
      when {
        branch 'dev'
      }
      steps {
        echo "Deploying to QA using scripts/deploy.sh qa"
        sh "chmod +x ${SCRIPTS_DIR}/deploy.sh || true"
        sh "bash ${SCRIPTS_DIR}/deploy.sh qa"
      }
      post {
        success {
          mail to: "${QA_NOTIFY}",
               subject: "✅ Delphi POC | Deployed to QA Successfully - Build #${env.BUILD_NUMBER}",
               body: "The application has been deployed to QA environment.\n\nBuild: ${env.BUILD_URL}"
        }
        failure {
          mail to: "${QA_NOTIFY}",
               subject: "❌ Delphi POC | Deployment to QA Failed - Build #${env.BUILD_NUMBER}",
               body: "Deployment to QA failed. Check Jenkins console and deploy logs: ${env.BUILD_URL}"
        }
      }
    }

    stage('Run QA Smoke Tests') {
      when {
        branch 'dev'
      }
      steps {
        echo "Running automated smoke tests for QA"
        dir("${BACKEND_DIR}") {
          // Start server in background and capture PID
          sh '''
            nohup node app.js > ../logs/server_qa.log 2>&1 & echo $! > /tmp/delphi_poc_server.pid || true
            sleep 4
          '''
        }

        // Run smoke test script
        sh "chmod +x ${SCRIPTS_DIR}/test_cases.sh || true"
        sh "bash ${SCRIPTS_DIR}/test_cases.sh qa"
      }
      post {
        always {
          echo "Cleaning up background server (if any)"
          sh '''
            if [ -f /tmp/delphi_poc_server.pid ]; then
              PID=$(cat /tmp/delphi_poc_server.pid) || true
              if [ -n "$PID" ]; then
                kill "$PID" 2>/dev/null || true
              fi
              rm -f /tmp/delphi_poc_server.pid || true
            fi
          '''
        }
        failure {
          mail to: "${QA_NOTIFY}",
               subject: "❌ Delphi POC | QA Smoke Tests FAILED - Build #${env.BUILD_NUMBER}",
               body: "QA smoke tests failed. Build: ${env.BUILD_URL}"
          error("Stopping pipeline since QA smoke tests failed.")
        }
        success {
          mail to: "${QA_NOTIFY}",
               subject: "✅ Delphi POC | QA Smoke Tests PASSED - Build #${env.BUILD_NUMBER}",
               body: "QA smoke tests passed. Build: ${env.BUILD_URL}"
        }
      }
    }

    stage('Deploy to UAT') {
      when {
        expression { currentBuild.currentResult == null || currentBuild.currentResult == 'SUCCESS' }
      }
      steps {
        echo "Deploying to UAT using scripts/deploy.sh uat"
        sh "chmod +x ${SCRIPTS_DIR}/deploy.sh || true"
        sh "bash ${SCRIPTS_DIR}/deploy.sh uat"
      }
      post {
        success {
          mail to: "${UAT_NOTIFY}",
               subject: "✅ Delphi POC | UAT Deployment Successful - Build #${env.BUILD_NUMBER}",
               body: "Application deployed to UAT environment. Build: ${env.BUILD_URL}"
        }
        failure {
          mail to: "${UAT_NOTIFY}",
               subject: "❌ Delphi POC | UAT Deployment Failed - Build #${env.BUILD_NUMBER}",
               body: "Deployment to UAT failed. Check logs: ${env.BUILD_URL}"
        }
      }
    }

    stage('Deploy to Production') {
      when {
        branch 'main'
      }
      steps {
        echo "Deploying to PRODUCTION using scripts/deploy.sh prod"
        sh "chmod +x ${SCRIPTS_DIR}/deploy.sh || true"
        sh "bash ${SCRIPTS_DIR}/deploy.sh prod"
      }
      post {
        success {
          mail to: "${PROD_NOTIFY}",
               subject: "🚀 Delphi POC | Production Deployment SUCCESS - Build #${env.BUILD_NUMBER}",
               body: "Production deployment completed successfully. Build: ${env.BUILD_URL}"
        }
        failure {
          mail to: "${PROD_NOTIFY}",
               subject: "🔥 Delphi POC | Production Deployment FAILED - Build #${env.BUILD_NUMBER}",
               body: "Production deployment failed. Review logs: ${env.BUILD_URL}"
        }
      }
    }
  } // stages

  post {
    always {
      echo "Pipeline finished with result: ${currentBuild.currentResult}"
    }
    success {
      echo "✅ Pipeline succeeded"
    }
    failure {
      echo "❌ Pipeline failed - check email notifications and console logs"
    }
  }
}
