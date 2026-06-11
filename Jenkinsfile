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
                '''
            }
        }
    }
}