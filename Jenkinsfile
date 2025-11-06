// pipeline {
//     agent any

//     environment {
//         NODE_HOME = tool name: 'nodejs'
//         PATH = "${NODE_HOME}/bin:${env.PATH}"
//         REPO_URL = 'https://github.com/Vedant2000039/Delphi-Pipeline-POC.git'

//         DEV_NOTIFY  = 'vmulherkar@xtsworld.in'
//         QA_NOTIFY   = 'vmulherkar@xtsworld.in'
//         UAT_NOTIFY  = 'vmulherkar@xtsworld.in'
//         PROD_NOTIFY = 'vmulherkar@xtsworld.in'
//     }

//     options { 
//         disableConcurrentBuilds()
//         timestamps()
//         buildDiscarder(logRotator(numToKeepStr: '20')) 
//     }

//     stages {

//         stage('Checkout') {
//             steps { 
//                 git branch: 'dev', url: "${env.REPO_URL}" 
//             }
//         }

//         stage('Install Dependencies') {
//             steps { 
//                 dir('backend') { 
//                     sh 'npm install' 
//                 } 
//             }
//         }

//         stage('Unit Tests - Dev') {
//             steps { 
//                 dir('backend') { 
//                     sh 'npm test' 
//                 } 
//             }
//             post {
//                 success { 
//                     mail to: "${DEV_NOTIFY}", subject: "Unit Tests PASSED (Dev)", body: "${env.BUILD_URL}" 
//                 }
//                 failure { 
//                     mail to: "${DEV_NOTIFY}", subject: "Unit Tests FAILED (Dev)", body: "${env.BUILD_URL}" 
//                 }
//             }
//         }

//         stage('Deploy to QA') {
//             when { anyOf { branch 'dev'; branch 'main' } }
//             steps {
//                 sh 'chmod +x scripts/deploy.sh'
//                 sh 'bash scripts/deploy.sh qa'
//             }
//         }

//         stage('Run QA Tests') {
//             when { anyOf { branch 'dev'; branch 'main' } }
//             steps {
//                 sh 'chmod +x scripts/test_cases.sh'
//                 sh 'bash scripts/test_cases.sh qa'
//             }
//             post {
//                 failure {
//                     mail to: "${QA_NOTIFY}", subject: 'QA Test Failure', body: "${env.BUILD_URL}"
//                     error("QA tests failed.")
//                 }
//             }
//         }

//         stage('Deploy to UAT') {
//             when { expression { currentBuild.currentResult == 'SUCCESS' } }
//             steps { 
//                 sh 'bash scripts/deploy.sh uat' 
//             }
//             post {
//                 failure {
//                     mail to: "${UAT_NOTIFY}", subject: 'UAT Deployment Failed', body: "${env.BUILD_URL}"
//                 }
//             }
//         }

//         stage('Deploy to PROD') {
//             when { branch 'main' }
//             steps { 
//                 sh 'bash scripts/deploy.sh prod' 
//             }
//             post {
//                 failure {
//                     mail to: "${PROD_NOTIFY}", subject: 'PROD Deployment Failed', body: "${env.BUILD_URL}"
//                 }
//             }
//         }
//     }

//     post {
//         always { echo "Pipeline completed: ${currentBuild.currentResult}" }
//         success { echo "All stages succeeded" }
//         failure { echo "Some stages failed" }
//     }
// }

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

        // Your Jenkins credential id (secret text with the GitHub PAT)
        GIT_CRED_ID = 'github-token'
    }

    options {
        disableConcurrentBuilds()
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {

        // Optional: quick token check (safe, read-only check)
        stage('Git Token Quick Check') {
            steps {
                script {
                    withCredentials([string(credentialsId: "${env.GIT_CRED_ID}", variable: 'GIT_TOKEN')]) {
                        sh '''
                          set -e
                          TMPDIR=$(mktemp -d)
                          cd "$TMPDIR"
                          git clone --depth 1 "$REPO_URL" repo || git clone "$REPO_URL" repo
                          cd repo
                          git config user.email "ci@delphi-poc"
                          git config user.name "Delphi CI"
                          # Attempt an authenticated ls-remote (no push)
                          git ls-remote "https://${GIT_TOKEN}@github.com/Vedant2000039/Delphi-Pipeline-POC.git" || true
                          rm -rf "$TMPDIR"
                        '''
                    }
                }
            }
        }

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
                success {
                    script {
                        // Merge dev -> qa on QA pass
                        withCredentials([string(credentialsId: "${env.GIT_CRED_ID}", variable: 'GIT_TOKEN')]) {
                            sh '''
                              set -e
                              TMPDIR=$(mktemp -d)
                              cd "$TMPDIR"

                              # clone repo (read-only clone is fine)
                              git clone --no-tags --depth 1 "$REPO_URL" repo || git clone "$REPO_URL" repo
                              cd repo

                              git config user.email "ci@delphi-poc"
                              git config user.name "Delphi CI"

                              # fetch refs
                              git fetch origin dev:refs/remotes/origin/dev || true
                              git fetch origin qa:refs/remotes/origin/qa || true

                              # checkout qa
                              git checkout qa || git checkout -b qa

                              # ensure it's the latest remote qa
                              git reset --hard origin/qa || true

                              # perform non-interactive merge from origin/dev
                              if git merge --no-ff --no-edit origin/dev; then
                                  echo "Merge succeeded (dev -> qa), pushing..."
                                  REMOTE_URL="https://${GIT_TOKEN}@github.com/Vedant2000039/Delphi-Pipeline-POC.git"
                                  git push "${REMOTE_URL}" qa
                                  echo "Push complete: dev -> qa"
                              else
                                  echo "Merge conflict or error occurred (dev -> qa). Aborting merge."
                                  git merge --abort || true
                                  exit 1
                              fi

                              rm -rf "$TMPDIR"
                            '''
                        }
                    }
                }
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
                success {
                    script {
                        // Merge qa -> uat on successful UAT deploy
                        withCredentials([string(credentialsId: "${env.GIT_CRED_ID}", variable: 'GIT_TOKEN')]) {
                            sh '''
                              set -e
                              TMPDIR=$(mktemp -d)
                              cd "$TMPDIR"

                              git clone --no-tags --depth 1 "$REPO_URL" repo || git clone "$REPO_URL" repo
                              cd repo

                              git config user.email "ci@delphi-poc"
                              git config user.name "Delphi CI"

                              git fetch origin qa:refs/remotes/origin/qa || true
                              git fetch origin uat:refs/remotes/origin/uat || true

                              git checkout uat || git checkout -b uat
                              git reset --hard origin/uat || true

                              if git merge --no-ff --no-edit origin/qa; then
                                  echo "Merge succeeded (qa -> uat), pushing..."
                                  REMOTE_URL="https://${GIT_TOKEN}@github.com/Vedant2000039/Delphi-Pipeline-POC.git"
                                  git push "${REMOTE_URL}" uat
                                  echo "Push complete: qa -> uat"
                              else
                                  echo "Merge conflict or error occurred (qa -> uat). Aborting merge."
                                  git merge --abort || true
                                  exit 1
                              fi

                              rm -rf "$TMPDIR"
                            '''
                        }
                    }
                }
                failure {
                    mail to: "${UAT_NOTIFY}", subject: 'UAT Deployment Failed', body: "${env.BUILD_URL}"
                }
            }
        }

        stage('Deploy to PROD') {
            // keep your original guard — deploy to prod only from main (adjust if you prefer a different trigger)
            when { branch 'main' }
            steps {
                sh 'bash scripts/deploy.sh prod'
            }
            post {
                success {
                    script {
                        // Merge uat -> prod on successful Prod deploy
                        withCredentials([string(credentialsId: "${env.GIT_CRED_ID}", variable: 'GIT_TOKEN')]) {
                            sh '''
                              set -e
                              TMPDIR=$(mktemp -d)
                              cd "$TMPDIR"

                              git clone --no-tags --depth 1 "$REPO_URL" repo || git clone "$REPO_URL" repo
                              cd repo

                              git config user.email "ci@delphi-poc"
                              git config user.name "Delphi CI"

                              git fetch origin uat:refs/remotes/origin/uat || true
                              git fetch origin prod:refs/remotes/origin/prod || true

                              git checkout prod || git checkout -b prod
                              git reset --hard origin/prod || true

                              if git merge --no-ff --no-edit origin/uat; then
                                  echo "Merge succeeded (uat -> prod), pushing..."
                                  REMOTE_URL="https://${GIT_TOKEN}@github.com/Vedant2000039/Delphi-Pipeline-POC.git"
                                  git push "${REMOTE_URL}" prod
                                  echo "Push complete: uat -> prod"
                              else
                                  echo "Merge conflict or error occurred (uat -> prod). Aborting merge."
                                  git merge --abort || true
                                  exit 1
                              fi

                              rm -rf "$TMPDIR"
                            '''
                        }
                    }
                }
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

