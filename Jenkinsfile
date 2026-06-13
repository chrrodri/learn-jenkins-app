pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = '64541461-c8d3-4288-8b22-2818a9bc0f4e'
    }

    stages {
        stage('BUILD') {
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
        }
        stage('TEST') {
             agent {
                docker {
                    image 'node:latest'
                    reuseNode true
                    args '-p 3000:3000'
                }
            }
            steps {
                sh '''
                    test -f public/index.html
                    npm test
                '''
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
            junit 'test-results/junit.xml'
        }
    }
}