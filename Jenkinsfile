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
    REPO = 'https://github.com/Vedant2000039/Delphi-Pipeline-POC.git'
    QA_DIR = 'D:/Delphi/environments/qa'
    UAT_DIR = 'D:/Delphi/environments/uat'
    PROD_DIR = 'D:/Delphi/environments/prod'

    QA_PORT = '5001'
    UAT_PORT = '5002'
    PROD_PORT = '5003'

    # credential id in Jenkins (Secret text) that stores a GitHub PAT with 'repo' scope
    GITHUB_CRED_ID = 'github-token'

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
    stage('Checkout dev') {
      when { branch 'dev' }
      steps {
        checkout([$class: 'GitSCM', branches: [[name: 'refs/heads/dev']], userRemoteConfigs: [[url: env.REPO]]])
        sh 'git rev-parse --abbrev-ref HEAD || true'
      }
    }

    stage('Install Dependencies') {
      steps {
        dir('backend') { sh 'npm ci' }
      }
    }

    stage('Unit Tests - Dev') {
      steps {
        dir('backend') { sh 'npm test' }
      }
      post {
        success {
          mail to: "${DEV_NOTIFY}", subject: "Unit Tests PASSED (dev) - ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "${env.BUILD_URL}"
        }
        failure {
          mail to: "${DEV_NOTIFY}", subject: "Unit Tests FAILED (dev) - ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "${env.BUILD_URL}"
          error "Unit tests failed — aborting pipeline"
        }
      }
    }

    ///////////////////////////
    // Promotion to QA
    ///////////////////////////
    stage('Promote dev → qa (update qa branch)') {
      when { branch 'dev' }
      steps {
        withCredentials([string(credentialsId: env.GITHUB_CRED_ID, variable: 'GITHUB_TOKEN')]) {
          sh '''
            set -euo pipefail

            # remote URL with token (masked by Jenkins)
            REMOTE="https://${GITHUB_TOKEN}@github.com/Vedant2000039/Delphi-Pipeline-POC.git"

            # ensure we are on the commit we tested
            SHA=$(git rev-parse HEAD)
            echo "Promoting commit ${SHA} to origin/qa"

            # Attempt to update origin/qa by setting its ref to this SHA.
            # This avoids creating new local commits; it forces the branch pointer.
            # If this push is blocked by protection, the push will fail and we fall back to PR creation.
            set +e
            git push "${REMOTE}" ${SHA}:refs/heads/qa --force
            PUSH_EXIT=$?
            set -e

            if [ "${PUSH_EXIT}" -eq 0 ]; then
              echo "Pushed commit ${SHA} to origin/qa"
            else
              echo "Direct push to origin/qa failed (protected?). Will create a Pull Request instead."
              # create a temp branch and open a PR using GitHub API
              TEMP="ci/qa-sync-${BUILD_NUMBER}-${SHA:0:7}"
              git checkout -b "${TEMP}"
              git push "${REMOTE}" "${TEMP}:refs/heads/${TEMP}"
              # create PR: title + body
              PR_TITLE="CI: promote dev ${BUILD_NUMBER} → qa"
              PR_BODY="Automated PR to promote tested commit ${SHA} into qa (created by Jenkins build ${BUILD_URL})."
              # Create PR using GitHub REST API (token must have repo scope)
              API_PAYLOAD=$(jq -n --arg t "${PR_TITLE}" --arg b "${PR_BODY}" --arg head "${TEMP}" --arg base "qa" '{title:$t, body:$b, head:$head, base:$base}')
              curl -s -H "Authorization: token ${GITHUB_TOKEN}" -X POST -d "${API_PAYLOAD}" "https://api.github.com/repos/Vedant2000039/Delphi-Pipeline-POC/pulls" > /tmp/pr_response.json
              PR_URL=$(jq -r '.html_url' /tmp/pr_response.json || echo "")
              if [ -z "${PR_URL}" ] || [ "${PR_URL}" = "null" ]; then
                echo "Failed to create PR; dumping API response:"
                cat /tmp/pr_response.json
                exit 1
              fi
              echo "Created PR: ${PR_URL}"
              # Fail the pipeline (or optionally pause for manual merge)
              echo "Please merge PR ${PR_URL} to continue automatic QA deployment."
              exit 2
            fi
          '''
        } // withCredentials
      }
    }

    stage('Clone/Update QA folder and Deploy') {
      when { branch 'dev' }
      steps {
        withCredentials([string(credentialsId: env.GITHUB_CRED_ID, variable: 'GITHUB_TOKEN')]) {
          sh '''
            set -euo pipefail
            TARGET="${QA_DIR}"
            REPO_AUTH="https://${GITHUB_TOKEN}@github.com/Vedant2000039/Delphi-Pipeline-POC.git"

            if [ -d "${TARGET}/.git" ]; then
              echo "Updating existing QA clone"
              git -C "${TARGET}" fetch --prune origin
              git -C "${TARGET}" checkout qa
              git -C "${TARGET}" reset --hard origin/qa
            else
              echo "Cloning origin/qa into ${TARGET}"
              rm -rf "${TARGET}"
              git clone --branch qa "${REPO_AUTH}" "${TARGET}"
            fi

            cd "${TARGET}"
            chmod +x scripts/deploy.sh
            bash scripts/deploy.sh qa
          '''
        }
      }
      post {
        failure {
          mail to: "${QA_NOTIFY}", subject: "QA Deploy Failed - ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "${env.BUILD_URL}"
          error "QA deployment failed"
        }
      }
    }

    stage('Run QA Tests') {
      when { branch 'dev' }
      steps {
        sh '''
          set -euo pipefail
          bash scripts/test_cases.sh http://localhost:${QA_PORT}
        '''
      }
      post {
        success {
          echo "QA tests passed"
        }
        failure {
          mail to: "${QA_NOTIFY}", subject: "QA Tests FAILED - ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "${env.BUILD_URL}"
          error "QA tests failed"
        }
      }
    }

    ///////////////////////////
    // Promotion to UAT (same pattern)
    ///////////////////////////
    stage('Promote qa → uat and Deploy') {
      // only proceed if QA succeeded
      when { expression { currentBuild.currentResult == null || currentBuild.currentResult == 'SUCCESS' } }
      steps {
        withCredentials([string(credentialsId: env.GITHUB_CRED_ID, variable: 'GITHUB_TOKEN')]) {
          sh '''
            set -euo pipefail
            REMOTE="https://${GITHUB_TOKEN}@github.com/Vedant2000039/Delphi-Pipeline-POC.git"
            SHA=$(git ls-remote origin refs/heads/qa | awk '{print $1}')
            echo "Promoting remote/qa commit ${SHA} to origin/uat"
            git push "${REMOTE}" ${SHA}:refs/heads/uat --force || (
              echo "Direct push to origin/uat failed; creating PR"
              TEMP="ci/uat-sync-${BUILD_NUMBER}-${SHA:0:7}"
              git checkout -b "${TEMP}"
              git push "${REMOTE}" "${TEMP}:refs/heads/${TEMP}"
              API_PAYLOAD=$(jq -n --arg t "CI: promote qa → uat ${BUILD_NUMBER}" --arg b "Auto PR from Jenkins" --arg head "${TEMP}" --arg base "uat" '{title:$t, body:$b, head:$head, base:$base}')
              curl -s -H "Authorization: token ${GITHUB_TOKEN}" -X POST -d "${API_PAYLOAD}" "https://api.github.com/repos/Vedant2000039/Delphi-Pipeline-POC/pulls" > /tmp/pr_response.json
              PR_URL=$(jq -r '.html_url' /tmp/pr_response.json || echo "")
              echo "Created PR: ${PR_URL}"
              exit 2
            )
          '''
        }
      }
    }

    stage('Clone/Update UAT folder and Deploy') {
      when { expression { currentBuild.currentResult == null || currentBuild.currentResult == 'SUCCESS' } }
      steps {
        withCredentials([string(credentialsId: env.GITHUB_CRED_ID, variable: 'GITHUB_TOKEN')]) {
          sh '''
            set -euo pipefail
            TARGET="${UAT_DIR}"
            REPO_AUTH="https://${GITHUB_TOKEN}@github.com/Vedant2000039/Delphi-Pipeline-POC.git"

            if [ -d "${TARGET}/.git" ]; then
              git -C "${TARGET}" fetch --prune origin
              git -C "${TARGET}" checkout uat
              git -C "${TARGET}" reset --hard origin/uat
            else
              git clone --branch uat "${REPO_AUTH}" "${TARGET}"
            fi

            cd "${TARGET}"
            chmod +x scripts/deploy.sh
            bash scripts/deploy.sh uat
          '''
        }
      }
      post {
        failure {
          mail to: "${UAT_NOTIFY}", subject: "UAT Deploy Failed - ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "${env.BUILD_URL}"
          error "UAT deployment failed"
        }
      }
    }

    stage('Run UAT Tests') {
      when { expression { currentBuild.currentResult == null || currentBuild.currentResult == 'SUCCESS' } }
      steps {
        sh 'bash scripts/test_cases.sh http://localhost:${UAT_PORT}'
      }
      post {
        failure {
          mail to: "${UAT_NOTIFY}", subject: "UAT Tests FAILED - ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "${env.BUILD_URL}"
          error "UAT tests failed"
        }
      }
    }

    ///////////////////////////
    // Promotion to PROD (main)
    ///////////////////////////
    stage('Promote uat → main and Deploy to Prod') {
      when { branch 'dev' } // run only from the dev-oriented run (you can change to explicit manual trigger)
      steps {
        withCredentials([string(credentialsId: env.GITHUB_CRED_ID, variable: 'GITHUB_TOKEN')]) {
          sh '''
            set -euo pipefail
            REMOTE="https://${GITHUB_TOKEN}@github.com/Vedant2000039/Delphi-Pipeline-POC.git"
            SHA=$(git ls-remote origin refs/heads/uat | awk '{print $1}')
            echo "Promoting remote/uat commit ${SHA} to origin/main"
            git push "${REMOTE}" ${SHA}:refs/heads/main --force || (
              echo "Direct push to origin/main failed; creating PR"
              TEMP="ci/prod-sync-${BUILD_NUMBER}-${SHA:0:7}"
              git checkout -b "${TEMP}"
              git push "${REMOTE}" "${TEMP}:refs/heads/${TEMP}"
              API_PAYLOAD=$(jq -n --arg t "CI: promote uat → main ${BUILD_NUMBER}" --arg b "Auto PR from Jenkins" --arg head "${TEMP}" --arg base "main" '{title:$t, body:$b, head:$head, base:$base}')
              curl -s -H "Authorization: token ${GITHUB_TOKEN}" -X POST -d "${API_PAYLOAD}" "https://api.github.com/repos/Vedant2000039/Delphi-Pipeline-POC/pulls" > /tmp/pr_response.json
              PR_URL=$(jq -r '.html_url' /tmp/pr_response.json || echo "")
              echo "Created PR: ${PR_URL}"
              exit 2
            )
          '''
        }
      }
    }

    stage('Clone/Update PROD folder and Deploy') {
      when { expression { currentBuild.currentResult == null || currentBuild.currentResult == 'SUCCESS' } }
      steps {
        withCredentials([string(credentialsId: env.GITHUB_CRED_ID, variable: 'GITHUB_TOKEN')]) {
          sh '''
            set -euo pipefail
            TARGET="${PROD_DIR}"
            REPO_AUTH="https://${GITHUB_TOKEN}@github.com/Vedant2000039/Delphi-Pipeline-POC.git"

            if [ -d "${TARGET}/.git" ]; then
              git -C "${TARGET}" fetch --prune origin
              git -C "${TARGET}" checkout main
              git -C "${TARGET}" reset --hard origin/main
            else
              git clone --branch main "${REPO_AUTH}" "${TARGET}"
            fi

            cd "${TARGET}"
            chmod +x scripts/deploy.sh
            bash scripts/deploy.sh prod
          '''
        }
      }
      post {
        failure {
          mail to: "${PROD_NOTIFY}", subject: "PROD Deploy Failed - ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "${env.BUILD_URL}"
          error "PROD deployment failed"
        }
      }
    }
  } // stages

  post {
    success { mail to: "${DEV_NOTIFY}", subject: "Pipeline SUCCEEDED - ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "${env.BUILD_URL}" }
    failure { mail to: "${DEV_NOTIFY}", subject: "Pipeline FAILED - ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "${env.BUILD_URL}" }
    always { echo "Pipeline done: ${currentBuild.currentResult}" }
  }
}
