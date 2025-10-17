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
                    bat 'npm install'
                }
            }
        }

        stage('Test') {
            steps {
                dir('backend') {
                    bat 'npm test'
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    if (env.GIT_BRANCH == "origin/dev") {
                        bat 'scripts\\deploy.bat dev'
                    } else if (env.GIT_BRANCH == "origin/qa") {
                        bat 'scripts\\deploy.bat qa'
                    } else if (env.GIT_BRANCH == "origin/main") {
                        bat 'scripts\\deploy.bat prod'
                    }
                }
            }
        }
    }
}
