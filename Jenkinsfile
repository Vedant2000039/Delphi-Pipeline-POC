pipeline {
    agent any

    environment {
        NODE_HOME = tool name: 'nodejs'
        PATH = "${NODE_HOME}/bin:${env.PATH}"
        REPO_URL = 'https://github.com/Vedant2000039/Delphi-Pipeline-POC.git'

        DEV_NOTIFY  = 'vmulherkar@xtsworld.in'
        QA_NOTIFY   = 'vmulherkar@xtsworld.in'
        UAT_NOTIFY  = 'vmulherkar@xtsworld.in'
        PROD_NOTIFY = 'vmulherkar@xtsworld.in'
    }

    options { 
        disableConcurrentBuilds()
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20')) 
    }

    stages {

        stage('Checkout') {
            steps { 
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

        stage('Unit Tests - Dev') {
            steps { 
                dir('backend') { 
                    sh 'npm test' 
                } 
            }
            post {
                success { 
                    mail to: "${DEV_NOTIFY}", subject: "Unit Tests PASSED (Dev)", body: "${env.BUILD_URL}" 
                }
                failure { 
                    mail to: "${DEV_NOTIFY}", subject: "Unit Tests FAILED (Dev)", body: "${env.BUILD_URL}" 
                }
            }
        }

        stage('Deploy to QA') {
            when { anyOf { branch 'dev'; branch 'main' } }
            steps {
                sh 'chmod +x scripts/deploy.sh'
                sh 'bash scripts/deploy.sh qa'
            }
        }

        stage('Run QA Tests') {
            when { anyOf { branch 'dev'; branch 'main' } }
            steps {
                sh 'chmod +x scripts/test_cases.sh'
                sh 'bash scripts/test_cases.sh qa'
            }
            post {
                failure {
                    mail to: "${QA_NOTIFY}", subject: 'QA Test Failure', body: "${env.BUILD_URL}"
                    error("QA tests failed.")
                }
            }
        }

        stage('Deploy to UAT') {
            when { expression { currentBuild.currentResult == 'SUCCESS' } }
            steps { 
                sh 'bash scripts/deploy.sh uat' 
            }
            post {
                failure {
                    mail to: "${UAT_NOTIFY}", subject: 'UAT Deployment Failed', body: "${env.BUILD_URL}"
                }
            }
        }

        stage('Deploy to PROD') {
            when { branch 'main' }
            steps { 
                sh 'bash scripts/deploy.sh prod' 
            }
            post {
                failure {
                    mail to: "${PROD_NOTIFY}", subject: 'PROD Deployment Failed', body: "${env.BUILD_URL}"
                }
            }
        }
    }

    post {
        always { echo "Pipeline completed: ${currentBuild.currentResult}" }
        success { echo "All stages succeeded" }
        failure { echo "Some stages failed" }
    }
}



