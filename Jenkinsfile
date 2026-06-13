pipeline {
    agent none

    options {
        timestamps()
        //ansiColor('xterm')
        skipStagesAfterUnstable()
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        NODE_IMAGE = 'node:22-alpine'
        PLAYWRIGHT_IMAGE = 'mcr.microsoft.com/playwright:v1.61.0-noble'

        NETLIFY_SITE_ID = '64541461-c8d3-4288-8b22-2818a9bc0f4e'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
    }

    stages {

        stage('Build') {
            agent {
                docker {
                    image "${NODE_IMAGE}"
                    reuseNode true
                }
            }

            steps {
                sh '''
                    echo "Node version:"
                    node --version

                    echo "NPM version:"
                    npm --version

                    echo "Installing dependencies..."
                    npm ci

                    echo "Building application..."
                    npm run build
                '''
            }

            post {
                success {
                    archiveArtifacts artifacts: 'build/**', fingerprint: true
                }
            }
        }

        stage('Tests') {

            parallel {

                stage('Unit Tests') {

                    agent {
                        docker {
                            image "${NODE_IMAGE}"
                            reuseNode true
                        }
                    }

                    steps {
                        sh '''
                            npm ci
                            npm test
                        '''
                    }

                    post {
                        always {
                            junit allowEmptyResults: true,
                                  testResults: 'jest-results/*.xml'
                        }
                    }
                }

                stage('E2E Tests') {

                    agent {
                        docker {
                            image "${PLAYWRIGHT_IMAGE}"
                            reuseNode true
                        }
                    }

                    steps {
                        sh '''
                            npm ci

                            npx serve -s build &
                            SERVER_PID=$!

                            sleep 10

                            npx playwright test --reporter=html

                            kill $SERVER_PID
                        '''
                    }

                    post {
                        always {
                            publishHTML([
                                allowMissing: false,
                                icon: '',
                                reportDir: 'playwright-report',
                                reportFiles: 'index.html',
                                reportName: 'Playwright HTML Report',
                                reportTitles: '', 
                                useWrapperFileDirectly: true,
                                keepAll: false,
                                alwaysLinkToLastBuild: false
                            ])

                            archiveArtifacts artifacts: 'playwright-report/**',
                                             allowEmptyArchive: true
                        }
                    }
                }
            }
        }

        stage('Deploy to Netlify') {

            agent {
                docker {
                    image "${NODE_IMAGE}"
                    reuseNode true
                }
            }

            when {
                branch 'main'
            }

            steps {
                sh '''
                    npm ci

                    npm install -g netlify-cli@20.12.2

                    echo "Deploying to Netlify..."
                    netlify deploy \
                        --dir=build \
                        --prod \
                        --site=$NETLIFY_SITE_ID
                '''
            }
        }
    }

    post {

        success {
            echo "Pipeline completed successfully."
        }

        failure {
            echo "Pipeline failed."
        }

        always {
            cleanWs()
        }
    }
}