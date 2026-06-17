pipeline {

    agent any

    options {
        timestamps()
        //ansiColor('xterm')
        skipStagesAfterUnstable()
        //timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        NODE_IMAGE = 'node:22-alpine'
        PLAYWRIGHT_IMAGE = 'mcr.microsoft.com/playwright:v1.61.0-noble'
        AWS_IMAGE = 'amazon/aws-cli:2.7.19'
        APP_VERSION = "1.0.${env.BUILD_NUMBER}"
    }

    stages {

        stage('BUILD') {

            stages {
                 stage('Sast Secret Scan') {
                    agent {
                        docker {
                            image 'zricethezav/gitleaks:latest'
                            args '--entrypoint=""'
                            reuseNode true
                        }
                    }
                    steps {
                        sh 'echo "Running SAST Secret Scan with Gitleaks..."'
                        sh '''
                            gitleaks detect \
                                --source . \
                                --report-format json \
                                --report-path gitleaks-report.json
                        '''
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'gitleaks-report.json'
                        }
                    } 
                }

                stage('Code Scan') {
                    agent {
                        docker {
                            image 'sonarsource/sonar-scanner-cli:latest'
                            reuseNode true
                        }
                    }
                    environment {
                        SONAR_TOKEN = credentials('sonarcloud-token')
                    }
                    steps {
                        sh 'echo "Running Code Scan with SonarCloud"'

                        sh '''
                        sonar-scanner \
                        -Dsonar.token=$SONAR_TOKEN
                        '''
                    }
                } 

                 stage('Sast Fortify') {
                     agent {
                        docker {
                            image 'semgrep/semgrep'
                            args '-v $WORKSPACE:/src'
                            reuseNode true
                        }
                    } 
                    steps {
                        sh 'echo "Running SAST Scan with Semgrep"'

                        sh '''
                            semgrep scan \
                            --config auto \
                            --json \
                            --output semgrep-report.json \
                            /src
                        '''
                    }
                     post {
                        always {
                            archiveArtifacts artifacts: 'semgrep-report.json'
                        }
                    }  
                }
              stage('Sast Security Scan') {
                    agent {
                        docker {
                            image 'aquasec/trivy:latest'
                            reuseNode true
                        }
                    }
                    steps {

                    sh '''
                        trivy fs \
                        --scanners vuln,secret \
                        --format json \
                        --output trivy-report.json \
                        .
                    '''
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-report.json'
                        }
                    }
                } 

                 stage('Action Chain Tests') {
                     agent {
                        docker {
                            image "${PLAYWRIGHT_IMAGE}"
                            reuseNode true
                        }
                    }  

                    steps {
                        sh 'echo "Running E2E Tests with Playwright"'
                        
                        sh '''
                            npx serve -s build &
                            SERVER_PID=$!

                            sleep 10
                            npx playwright install chromium --with-deps
                            npx playwright test --reporter=html

                            kill $SERVER_PID
                        '''  
                    }
                } 
 
                stage('Unit Tests') {
                    agent {
                        docker {
                            image "${NODE_IMAGE}"
                            reuseNode true
                        }
                    }
                    steps {
                        sh 'echo "Running Unit Tests"'
                        npm test
                    }
                } */

/*                 stage('Package') {
                    agent {
                        docker {
                            image "${NODE_IMAGE}"
                            reuseNode true
                        }
                    }
                    steps {
                        sh 'echo "Running Package Stage"'
                        sh '''
   
                            npm run build
                            zip -r build.zip build
                        '''
                        
                    }
                    post {
                        success {
                            archiveArtifacts artifacts: 'build.zip', fingerprint: true
                        }
                    }
                } */

/*                 stage('Publish') {

                    steps {
                        sh '''
                        aws --version
                        aws s3 cp build.zip \
                        s3://chrrodri-build-artifacts/build.zip
                        '''
                    }
                } */
            }
        }
    
/*         stage('DEPLOY') {
            stages {
                stage('Deploy') {
                    steps {
                        //sh 'kubectl apply -f deployment.yaml'
                        sh 'echo "Running Deploy Stage"'
                    }
                }
            }
        } */

/*         stage('TEST') {
            stages {
                stage('Integration Tests') {
                    steps {
                       //sh './integration-tests.sh'
                        sh 'echo "Running Integration Tests"'
                    }
                }
                stage('Gelato Scan') {
                    steps {
                        //sh './integration-tests.sh'
                        sh 'echo "Running Gelato Scan"'
                    }
                }
                stage('Custom Security Check') {
                    steps {
                        //sh './integration-tests.sh'
                        sh 'echo "Running Custom Security Check"'
                    }
                }
                 stage('Gat Itaas') {
                    steps {
                        //sh './integration-tests.sh'
                        sh 'echo "Running Gat Itaas"'
                    }
                }
            }
        } */
    }
}