pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = '64541461-c8d3-4288-8b22-2818a9bc0f4e'
    }

    stages {
       /* stage('BUILD') {
           agent {
                docker {
                    image 'node:latest'
                    reuseNode true
                    args '-p 3000:3000'
                }
            }
            steps {
                sh '''
                    ls -la
                    node --version
                    npm --version
                    npm ci
                    npm run build
                '''
            }
        }*/
        stage('TEST') {
            parallel {
                stage('Unit Tests') {
                    agent {
                        docker {
                            image 'node:latest'
                            reuseNode true
                            args '-p 3000:3000'
                        }
                    }
                    steps {
                        sh '''
                            test -f build/index.html
                            npm test
                        '''
                    }
                }

                stage('E2E Tests') {
                    agent {
                        docker {
                            
                            image 'mrc.microsoft.com/playwright:v1.61.0-jammy'
                            reuseNode true
                            args '-p 3000:3000'
                        }
                    }
                    steps {
                        sh '''
                            npm install serve
                            node_modules/.bin/serve -s build &
                            sleep 20
                            npx playwright test --reporter=html
                        '''
                    }
                }
            }
        }

        stage('DEPLOY') {
             agent {
                docker {
                    image 'node:latest'
                    reuseNode true
                    args '-p 3000:3000'
                }
            }
            steps {
                sh '''
                    npm install netlify-cli
                    node_modules/.bin/netlify --version
                    echo "Deploying to production. Site ID = $NETLIFY_SITE_ID"
                '''
            }
        }
    }
    post {
        always {
            junit 'jest-results/junit.xml'
            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright HTML Report', reportTitles: '', useWrapperFileDirectly: true])
        }
    }
}