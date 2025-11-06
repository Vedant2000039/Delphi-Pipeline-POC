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

    // Jenkins credential id (Secret text) that stores a GitHub PAT with 'repo' scope
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

    stage('Checkout (branch)') {
      steps {
        echo "Branch: ${env.BRANCH_NAME}"
        // ensure workspace is on the branch that triggered the job
        checkout scm
      }
    }

    stage('Install Dependencies') {
      steps {
        dir('backend') {
          sh '''
set -euo pipefail
npm ci
'''
        }
      }
    }

    stage('Unit Tests - Dev') {
      when { expression { env.BRANCH_NAME == 'dev' } }
      steps {
        dir('backend') {
          sh '''bash -lc <<'BASH'
set -euo pipefail
npm test
BASH
'''
        }
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

    stage('Promote dev → qa (update qa branch)') {
      when { expression { env.BRANCH_NAME == 'dev' } }
      steps {
        withCredentials([string(credentialsId: env.GITHUB_CRED_ID, variable: 'GITHUB_TOKEN')]) {
          sh '''bash -lc <<'BASH'
set -euo pipefail

REMOTE="https://${GITHUB_TOKEN}@github.com/Vedant2000039/Delphi-Pipeline-POC.git"
SHA=$(git rev-parse HEAD)
echo "Promoting commit ${SHA} to origin/qa"

# try to set origin/qa to this exact SHA (fast & exact)
set +e
git push "${REMOTE}" ${SHA}:refs/heads/qa --force
PUSH_EXIT=$?
set -e

if [ "${PUSH_EXIT}" -ne 0 ]; then
  echo "Direct push to origin/qa failed (likely protected). Creating PR to promote commit."
  TEMP="ci/qa-sync-${BUILD_NUMBER}-${SHA:0:7}"
  git checkout -b "${TEMP}"
  git push "${REMOTE}" "${TEMP}:refs/heads/${TEMP}"

  PR_TITLE="CI: promote dev ${BUILD_NUMBER} → qa"
  PR_BODY="Automated PR to promote tested commit ${SHA} into qa (Jenkins build ${BUILD_URL})."
  # requires 'jq' on agent; if not installed request jq-free variant
  API_PAYLOAD=$(jq -n --arg t "${PR_TITLE}" --arg b "${PR_BODY}" --arg head "${TEMP}" --arg base "qa" '{title:$t, body:$b, head:$head, base:$base}')
  curl -s -H "Authorization: token ${GITHUB_TOKEN}" -X POST -d "${API_PAYLOAD}" "https://api.github.com/repos/Vedant2000039/Delphi-Pipeline-POC/pulls" > /tmp/pr_response.json
  PR_URL=$(jq -r '.html_url' /tmp/pr_response.json || echo "")
  echo "PR created: ${PR_URL}"
  echo "Please merge PR ${PR_URL} to continue QA deployment."
  exit 2
else
  echo "Pushed commit ${SHA} to origin/qa"
fi
BASH
'''
        }
      }
    }

    stage('Clone/Update QA branch and Deploy (from qa)') {
      when { expression { env.BRANCH_NAME == 'dev' } }
      steps {
        withCredentials([string(credentialsId: env.GITHUB_CRED_ID, variable: 'GITHUB_TOKEN')]) {
          sh '''bash -lc <<'BASH'
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
BASH
'''
        }
      }
      post {
        failure {
          mail to: "${QA_NOTIFY}", subject: "QA Deploy FAILED - ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "${env.BUILD_URL}"
          error "QA deployment failed"
        }
      }
    }

    stage('Run QA Tests') {
      when { expression { env.BRANCH_NAME == 'dev' } }
      steps {
        sh '''bash -lc <<'BASH'
set -euo pipefail
bash scripts/test_cases.sh http://localhost:${QA_PORT}
BASH
'''
      }
      post {
        success { echo "QA tests passed" }
        failure {
          mail to: "${QA_NOTIFY}", subject: "QA Tests FAILED - ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "${env.BUILD_URL}"
          error "QA tests failed"
        }
      }
    }

    stage('Promote qa → uat (update uat branch)') {
      when { expression { env.BRANCH_NAME == 'dev' } }
      steps {
        withCredentials([string(credentialsId: env.GITHUB_CRED_ID, variable: 'GITHUB_TOKEN')]) {
          sh '''bash -lc <<'BASH'
set -euo pipefail

REMOTE="https://${GITHUB_TOKEN}@github.com/Vedant2000039/Delphi-Pipeline-POC.git"
SHA=$(git ls-remote origin refs/heads/qa | awk '{print $1}')
echo "Promoting remote/qa commit ${SHA} to origin/uat"

set +e
git push "${REMOTE}" ${SHA}:refs/heads/uat --force
PUSH_EXIT=$?
set -e

if [ "${PUSH_EXIT}" -ne 0 ]; then
  echo "Direct push failed; creating PR for uat"
  TEMP="ci/uat-sync-${BUILD_NUMBER}-${SHA:0:7}"
  git checkout -b "${TEMP}"
  git push "${REMOTE}" "${TEMP}:refs/heads/${TEMP}"
  API_PAYLOAD=$(jq -n --arg t "CI: promote qa → uat ${BUILD_NUMBER}" --arg b "Auto PR from Jenkins" --arg head "${TEMP}" --arg base "uat" '{title:$t, body:$b, head:$head, base:$base}')
  curl -s -H "Authorization: token ${GITHUB_TOKEN}" -X POST -d "${API_PAYLOAD}" "https://api.github.com/repos/Vedant2000039/Delphi-Pipeline-POC/pulls" > /tmp/pr_response.json
  PR_URL=$(jq -r '.html_url' /tmp/pr_response.json || echo "")
  echo "PR created: ${PR_URL}"
  exit 2
fi
BASH
'''
        }
      }
    }

    stage('Clone/Update UAT branch and Deploy (from uat)') {
      when { expression { env.BRANCH_NAME == 'dev' } }
      steps {
        withCredentials([string(credentialsId: env.GITHUB_CRED_ID, variable: 'GITHUB_TOKEN')]) {
          sh '''bash -lc <<'BASH'
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
BASH
'''
        }
      }
      post {
        failure {
          mail to: "${UAT_NOTIFY}", subject: "UAT Deploy FAILED - ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "${env.BUILD_URL}"
          error "UAT deployment failed"
        }
      }
    }

    stage('Run UAT Tests') {
      when { expression { env.BRANCH_NAME == 'dev' } }
      steps {
        sh '''bash -lc <<'BASH'
set -euo pipefail
bash scripts/test_cases.sh http://localhost:${UAT_PORT}
BASH
'''
      }
      post {
        failure {
          mail to: "${UAT_NOTIFY}", subject: "UAT Tests FAILED - ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "${env.BUILD_URL}"
          error "UAT tests failed"
        }
      }
    }

    stage('Promote uat → main (update main) and Deploy (prod)') {
      when { expression { env.BRANCH_NAME == 'dev' } }
      steps {
        withCredentials([string(credentialsId: env.GITHUB_CRED_ID, variable: 'GITHUB_TOKEN')]) {
          sh '''bash -lc <<'BASH'
set -euo pipefail

REMOTE="https://${GITHUB_TOKEN}@github.com/Vedant2000039/Delphi-Pipeline-POC.git"
SHA=$(git ls-remote origin refs/heads/uat | awk '{print $1}')
echo "Promoting remote/uat commit ${SHA} to origin/main"

set +e
git push "${REMOTE}" ${SHA}:refs/heads/main --force
PUSH_EXIT=$?
set -e

if [ "${PUSH_EXIT}" -ne 0 ]; then
  echo "Direct push failed; creating PR for prod"
  TEMP="ci/prod-sync-${BUILD_NUMBER}-${SHA:0:7}"
  git checkout -b "${TEMP}"
  git push "${REMOTE}" "${TEMP}:refs/heads/${TEMP}"
  API_PAYLOAD=$(jq -n --arg t "CI: promote uat → main ${BUILD_NUMBER}" --arg b "Auto PR from Jenkins" --arg head "${TEMP}" --arg base "main" '{title:$t, body:$b, head:$head, base:$base}')
  curl -s -H "Authorization: token ${GITHUB_TOKEN}" -X POST -d "${API_PAYLOAD}" "https://api.github.com/repos/Vedant2000039/Delphi-Pipeline-POC/pulls" > /tmp/pr_response.json
  PR_URL=$(jq -r '.html_url' /tmp/pr_response.json || echo "")
  echo "PR created: ${PR_URL}"
  exit 2
fi
BASH
'''
        }
      }
    }

    stage('Clone/Update PROD branch and Deploy (from main)') {
      when { expression { env.BRANCH_NAME == 'dev' } }
      steps {
        withCredentials([string(credentialsId: env.GITHUB_CRED_ID, variable: 'GITHUB_TOKEN')]) {
          sh '''bash -lc <<'BASH'
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
BASH
'''
        }
      }
      post {
        failure {
          mail to: "${PROD_NOTIFY}", subject: "PROD Deploy FAILED - ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "${env.BUILD_URL}"
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


