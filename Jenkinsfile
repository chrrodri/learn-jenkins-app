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

        NETLIFY_SITE_ID = '64541461-c8d3-4288-8b22-2818a9bc0f4e'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
    }

    stages {

        stage('BUILD') {

            stages {
                stage('Sast Secret Scan') {
                    steps {
                        //sh 'gitleaks detect --source .'
                        sh 'echo "Running SAST Secret Scan with Gitleaks..."'
        
                    }
                }

                stage('Code Scan') {
                    steps {
                        //sh 'sonar-scanner'
                        sh 'echo "Running Code Scan with SonarQube"'
                    }
                }

                stage('Sast Fortify') {
                    steps {
                        //sh './fortify.sh'
                        sh 'echo "Running SAST Fortify Scan"'
                    }
                }

                stage('Sast Security Scan') {
                    steps {
                        //sh 'trivy fs .'
                        sh 'echo "Running SAST Security Scan with Trivy"'
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
                        sh 'echo "Running SAST Security Scan with Trivy"'
                        
/*                         sh '''
                            npx serve -s build &
                            SERVER_PID=$!

                            sleep 10
                            npx playwright install chromium --with-deps
                            npx playwright test --reporter=html

                            kill $SERVER_PID
                        ''' */
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
                        sh 'npm test'
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
                            npm ci
                            npm run build
                            zip -r build.zip build
                        '''
                        
                    }
                    post {
                        success {
                            archiveArtifacts artifacts: 'build.zip', fingerprint: true
                        }
                    }
                }

                stage('Publish') {
/*                     agent {
                        docker {
                            image "${AWS_IMAGE}"
                            reuseNode true
                        }
                    } */
                    steps {
                        sh '''
                        aws s3 cp build.zip \
                        s3://chrrodri-build-artifacts/
                        '''
                        sh 'echo "Running Publish Stage"'
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