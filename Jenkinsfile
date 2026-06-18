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
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION    = 'us-east-1'
    }

    stages {

        stage('BUILD') {

            stages {
                stage('Install Dependencies') {
                    agent {
                        docker {
                            image "${NODE_IMAGE}"
                            reuseNode true
                        }
                    }

                    steps {
                        sh '''
                            npm install
                            npm ci
                        '''
                        stash includes: 'node_modules/**', name: 'node_modules'
                    }
                }
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
                            args '--entrypoint="" --user root'
                            reuseNode true
                        }
                    }
                    steps {

                    sh 'echo "Running SAST Security Scan with Trivy"'

                    sh '''
                        mkdir -p /tmp/trivy-cache

                        trivy fs \
                        --cache-dir /tmp/trivy-cache \
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
                            args '--entrypoint=""'
                            reuseNode true
                        }
                    }  
                    steps {
                        sh 'echo "Running E2E Tests with Playwright"'
                        
                        sh '''
                            npx playwright test 
                        '''  
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'test-results/*.xml'

                            archiveArtifacts(
                                artifacts: '''
                                    playwright-report/**,
                                    test-results/**
                                ''',
                                allowEmptyArchive: true
                            )
                        }
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

                        sh '''
                            CI=true npm run test:ci
                        '''
                    }
                    post {
                        always {
                            junit allowEmptyResults: true,
                                testResults: 'test-results/junit.xml'

                            archiveArtifacts(
                                artifacts: '''
                                    coverage/**,
                                    test-results/**
                                ''',
                                allowEmptyArchive: true
                            )
                        }
                    }
                }

                 stage('Package') {
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
                            tar -czf build-${APP_VERSION}.tar.gz build
                        '''
                        
                    }
                    post {
                        success {
                            archiveArtifacts(
                                artifacts: '*.tar.gz',
                                fingerprint: true
                            )

                            archiveArtifacts(
                                artifacts: 'build/**',
                                fingerprint: true
                            )
                        }
                    }
                } 

                 stage('Publish') {
                    agent {
                        docker {
                            image 'amazon/aws-cli:2'
                            reuseNode true
                        }
                    }
                    steps {
                        withCredentials([
                            string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                            string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                        ]) {

                            sh '''
                            export AWS_DEFAULT_REGION=us-east-1

                            aws s3 cp \
                            build-${APP_VERSION}.tar.gz \
                            s3://chrrodri-build-artifacts/build-${APP_VERSION}.tar.gz
                            '''
                        }
                    }
                } 
            }
        }
    
         stage('DEPLOY') {
            stages {
                stage('Deploy') {
                    steps {
                        //sh 'kubectl apply -f deployment.yaml'
                        sh 'echo "Running Deploy Stage"'
                    }
                }
            }
        }

         stage('TEST') {
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
        } 
    }
}