pipeline {

    agent any

    stages {

        stage('BUILD') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            stages {
                stage('Sast Secret Scan') {
                    steps {
                        sh 'echo "Running SAST Secret Scan with Gitleaks"'
                        //sh 'gitleaks detect --source .'
                        
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
                    steps {
                        sh 'echo "Running Action Chain Tests"'
                        sh 'npm run test:e2e'

                    }
                }

                stage('Unit Tests') {
                    steps {
                        sh 'echo "Running Unit Tests"'
                        sh 'npm test'
                    }
                }

                stage('Package') {
                    steps {
                        sh 'echo "Running Package Stage"'
                        sh 'npm run build'
                    }
                }

                stage('Publish') {
                    steps {
                        /*sh '''
                        aws s3 cp dist.zip \
                        s3://artifacts-bucket/
                        '''*/
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