pipeline {
    agent any
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
                    ls -la
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
                    test -f build/index.html
                    npm test
                '''
            }
        }
    }
}