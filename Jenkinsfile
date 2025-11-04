pipeline {
  agent any

  environment {
    NODE_HOME = tool name: 'nodejs'
    PATH = "${NODE_HOME}/bin:${env.PATH}"
    REPO_URL = 'https://github.com/Vedant2000039/Delphi-Pipeline-POC.git'

    // Notification emails
    DEV_NOTIFY  = 'vmulherkar@xtsworld.in'
    QA_NOTIFY   = 'vmulherkar@xtsworld.in'
    UAT_NOTIFY  = 'vmulherkar@xtsworld.in'
    PROD_NOTIFY = 'vmulherkar@xtsworld.in'
  }

  options {
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
    timestamps()
  }

  stages {

    /* =========================
        CHECKOUT STAGE
    ========================== */
    stage('Checkout') {
      steps {
        echo "Checking out 'dev' branch by default..."
        git branch: 'dev', url: "${env.REPO_URL}"
      }
      post {
        success {
          mail to: "${DEV_NOTIFY}",
               subject: "✅ Checkout SUCCESS - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
               body: "Checkout completed successfully. Build URL: ${env.BUILD_URL}"
        }
        failure {
          mail to: "${DEV_NOTIFY}",
               subject: "❌ Checkout FAILED - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
               body: "Checkout failed. Check console log: ${env.BUILD_URL}"
        }
      }
    }

    /* =========================
        INSTALL DEPENDENCIES
    ========================== */
    stage('Install Dependencies') {
      steps {
        dir('backend') {
          sh 'npm install'
        }
      }
      post {
        success {
          mail to: "${DEV_NOTIFY}",
               subject: "✅ Install Dependencies PASSED - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
               body: "Dependencies installed successfully. Build URL: ${env.BUILD_URL}"
        }
        failure {
          mail to: "${DEV_NOTIFY}",
               subject: "❌ Install Dependencies FAILED - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
               body: "Dependency installation failed. Check console: ${env.BUILD_URL}"
        }
      }
    }

    /* =========================
       UNIT TESTS (DEV)
    ========================== */
    stage('Unit Tests - Dev') {
      steps {
        dir('backend') {
          sh 'npm test'
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

    /* =========================
       DEPLOY TO TEST (QA)
    ========================== */
    stage('Deploy to Test Environment (QA)') {
      when {
        branch 'main'
      }
      steps {
        echo "Deploying to TEST environment..."
        sh 'chmod +x scripts/deploy.sh || true'
        sh 'bash scripts/deploy.sh qa'
      }
      post {
        success {
          mail to: "${QA_NOTIFY}",
            subject: "✅ Delphi POC | Deployed to TEST Successfully - Build #${env.BUILD_NUMBER}",
            body: "The application has been deployed to TEST environment.\n\nCheck Jenkins: ${env.BUILD_URL}"
        }
        failure {
          mail to: "${QA_NOTIFY}",
            subject: "❌ Delphi POC | Deployment to TEST Failed - Build #${env.BUILD_NUMBER}",
            body: "Deployment to TEST failed. Logs: ${env.BUILD_URL}"
        }
      }
    }

    /* =========================
        RUN TEST CASES (QA)
    ========================== */
    stage('Run QA Test Cases') {
      steps {
        echo "Running automated test cases in QA..."
        dir('backend') {
          // Start server in background
          sh 'nohup node app.js > server.log 2>&1 &'
          // Wait for it to start
          sh 'sleep 5'
        }

        sh 'chmod +x scripts/test_cases.sh'
        sh 'bash scripts/test_cases.sh qa'
      }
      post {
        success {
          mail to: "${QA_NOTIFY}",
            subject: "✅ QA Tests PASSED - Build #${env.BUILD_NUMBER}",
            body: "QA smoke tests passed successfully. Build: ${env.BUILD_URL}"
        }
        failure {
          mail to: "${QA_NOTIFY}",
            subject: "❌ QA Tests FAILED - Build #${env.BUILD_NUMBER}",
            body: "QA tests failed. Check console and server logs: ${env.BUILD_URL}"
          // Keep existing behavior: stop pipeline on failure
          script { error("Stopping pipeline since QA test cases failed.") }
        }
      }
    }

    /* =========================
       DEPLOY TO UAT
    ========================== */
    stage('Deploy to UAT Environment') {
      when {
        expression { currentBuild.currentResult == 'SUCCESS' }
      }
      steps {
        echo "Deploying to UAT environment..."
        sh 'chmod +x scripts/deploy.sh || true'
        sh 'bash scripts/deploy.sh uat'
      }
      post {
        success {
          mail to: "${UAT_NOTIFY}",
            subject: "✅ Delphi POC | UAT Deployment Successful - Build #${env.BUILD_NUMBER}",
            body: "Application deployed to UAT environment. UAT team can start validation.\n\nURL: http://localhost:4003"
        }
        failure {
          mail to: "${UAT_NOTIFY}",
            subject: "❌ Delphi POC | UAT Deployment Failed - Build #${env.BUILD_NUMBER}",
            body: "Deployment to UAT failed. Logs: ${env.BUILD_URL}"
        }
      }
    }

    /* =========================
       DEPLOY TO PRODUCTION
    ========================== */
    stage('Deploy to Production Environment') {
      when {
        branch 'main'
      }
      steps {
        echo "Deploying to PRODUCTION..."
        sh 'chmod +x scripts/deploy.sh || true'
        sh 'bash scripts/deploy.sh prod'
      }
      post {
        success {
          mail to: "${PROD_NOTIFY}",
            subject: "🚀 Delphi POC | Production Deployment SUCCESS - Build #${env.BUILD_NUMBER}",
            body: "Production deployment completed successfully.\n\nURL: http://localhost:4000"
        }
        failure {
          mail to: "${PROD_NOTIFY}",
            subject: "🔥 Delphi POC | Production Deployment FAILED - Build #${env.BUILD_NUMBER}",
            body: "Production deployment failed. Review logs: ${env.BUILD_URL}"
        }
      }
    }
  }

  /* =========================
     POST PIPELINE ACTIONS
  ========================== */
  post {
    always {
      echo "Pipeline completed with result: ${currentBuild.currentResult}"
    }
    success {
      echo "✅ All stages executed successfully!"
    }
    failure {
      echo "❌ One or more stages failed. Check email notifications and console logs."
    }
  }
}
