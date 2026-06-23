pipeline {

    agent any

    options {
        timestamps()
        //ansiColor('xterm')
        skipStagesAfterUnstable()
        //timeout(time: 60, unit: 'MINUTES')
    }

    environment {
        GITLEAKS_IMAGE        = 'zricethezav/gitleaks:v8.28.0'
        SONARCLOUD_IMAGE      = 'sonarsource/sonar-scanner-cli:11.5'
        SEMGREP_IMAGE         = 'semgrep/semgrep:1.132.0'
        TRIVY_IMAGE           = 'aquasec/trivy:0.67.2'
        PLAYWRIGHT_IMAGE      = 'mcr.microsoft.com/playwright:v1.61.0-noble'
        //NODE_IMAGE            = 'node:22.19.0-alpine3.22'
        NODE_IMAGE            = 'chrrodri/node-deps:latest'
        AWS_IMAGE             = 'amazon/aws-cli:2.31.0'
        K8S_IMAGE             = 'bitnami/kubectl:latest'


        APP_NAME              = 'learn-jenkins-app'
        APP_VERSION           = "1.0.${env.BUILD_NUMBER}"

        SONAR_TOKEN           = credentials('sonarcloud-token')

        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION    = 'us-east-1'
        AWS_DIST_ID           = 'E14DJLE76ZBLY5'
        AWS_CLOUDFRONT_URL    = 'deegnr78of0qk.cloudfront.net'

    }

    stages {

        stage('BUILD') {

             stages {

                 stage('Sast Secret Scan') {
                    agent {
                        docker {
                            image "${GITLEAKS_IMAGE}"
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
                                --report-path gitleaks-report.json || true      
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
                            image "${SONARCLOUD_IMAGE}"
                            reuseNode true
                        }
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
                            image "${SEMGREP_IMAGE}"
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
                            image "${TRIVY_IMAGE}"
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
                            args '--entrypoint="" --user root'
                            reuseNode true
                        }
                    }  
                    steps {
                        sh 'echo "Running E2E Tests with Playwright"'
                        
                        sh '''
                            
                            npm ci

                            npm run build

                            npx serve -s build -l 3000 &
                            SERVER_PID=$!

                            # Espera activa (más estable que sleep fijo)
                            for i in $(seq 1 30); do
                            curl -s http://localhost:3000 && break
                            sleep 2
                            done

                            npx playwright test 

                            kill $SERVER_PID

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
                            args '--entrypoint="" --user root'
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
                            args '--entrypoint="" --user root'
                            reuseNode true
                        }
                    }
                    steps {
                        sh 'echo "Running Package Stage"'
                        sh '''
                            export REACT_APP_VERSION=${APP_VERSION}
                            npm run build                            
                        '''    
                    }
                    post {
                        success {
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
                            image "${NODE_IMAGE}"
                            args '--entrypoint="" --user root'
                            reuseNode true
                        }
                    }
                    steps {
                        script {

                            //
                            // START TIME PIPELINE
                            //
                            def startTime = currentBuild.startTimeInMillis

                            //
                            // Gitleaks
                            //
                            def gitleaksReport = readJSON file: 'gitleaks-report.json'
                            def gitleaksFindings = gitleaksReport.size()

                            //
                            // Semgrep
                            //
                            def semgrepReport = readJSON file: 'semgrep-report.json'
                            def semgrepFindings = semgrepReport.results.size()

                            //
                            // Trivy
                            //
                            def trivyReport = readJSON file: 'trivy-report.json'

                            int critical = 0
                            int high = 0

                            trivyReport.Results.each { result ->

                                if (result.Vulnerabilities) {

                                    result.Vulnerabilities.each { vuln ->

                                        if (vuln.Severity == "CRITICAL") {
                                            critical++
                                        }

                                        if (vuln.Severity == "HIGH") {
                                                    high++
                                        }
                                    }
                                }
                            

                            //
                            // Coverage
                            //
                            //def coverage = readJSON file: 'coverage/coverage-summary.json'
                            //def coveragePercent = coverage.total.lines.pct
                //coverage_percent ${coveragePercent}

                            //
                            // END TIME + DURATION
                            //
                            def endTime = System.currentTimeMillis()
                            def durationSeconds = (endTime - startTime) / 1000

                            //
                            // Crear archivo Prometheus
                            //
                            writeFile(
                                file: 'metrics.prom',
                                text: """
                gitleaks_findings_total ${gitleaksFindings}
                semgrep_findings_total ${semgrepFindings}
                trivy_critical ${critical}
                trivy_high ${high}
                pipeline_duration_seconds ${durationSeconds}
                """
                            )
                                sh '''
                                    curl --data-binary @metrics.prom \
                                    http://192.168.1.28:9091/metrics/job/jenkins-security
                                '''
                            }
                        }
                    }
                }
            }
        }
        
         stage('DEPLOY') {
            stages {
                stage('Deploy to CloudFront') {
                    agent {
                        docker {
                            image "${AWS_IMAGE}"
                            args '--entrypoint=""'
                            reuseNode true
                        }
                    }
                    steps {
                        withCredentials([
                            string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                            string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                        ]) {
                            sh 'echo "Publish to Cloudfront"' 
                            sh '''
                                export AWS_DEFAULT_REGION=us-east-1

                                aws s3 sync build/ \
                                s3://chrrodri-$APP_NAME \
                                --delete

                                aws cloudfront create-invalidation \
                                    --distribution-id $AWS_DIST_ID \
                                    --paths "/*"

                                echo "Cloudfront URL: https://$AWS_CLOUDFRONT_URL"
                            '''
                        }
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
    post { 
        always { 
            cleanWs()
        } 
    }    
}