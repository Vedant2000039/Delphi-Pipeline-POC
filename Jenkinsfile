pipeline {
    agent any

    environment {
        NODE_HOME = tool name: 'nodejs'  // Jenkins Node.js tool
        PATH = "${NODE_HOME}/bin:${env.PATH}"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'dev', url: 'https://github.com/Vedant2000039/Delphi-Pipeline-POC.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                dir('backend') {
                    sh 'npm install'
                }
            }
        }

        stage('Test') {
            steps {
                dir('backend') {
                    sh 'npm test'
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    if (env.GIT_BRANCH == "origin/dev") {
                        sh 'bash scripts/deploy.sh dev'
                    } else if (env.GIT_BRANCH == "origin/qa") {
                        sh 'bash scripts/deploy.sh qa'
                    } else if (env.GIT_BRANCH == "origin/main") {
                        sh 'bash scripts/deploy.sh prod'
                    }
                }
            }
        }
    }
}
