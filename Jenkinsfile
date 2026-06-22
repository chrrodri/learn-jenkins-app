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
        NODE_IMAGE            = 'node:22.19.0-alpine3.22'
        AWS_IMAGE             = 'amazon/aws-cli:2.31.0'
        K8S_IMAGE             = 'bitnami/kubectl:latest'


        APP_NAME              = 'learn-jenkins-app'
        APP_VERSION           = "1.0.${env.BUILD_NUMBER}"

        SONAR_TOKEN           = credentials('sonarcloud-token')

        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION    = 'us-east-1'
        AWS_DIST_ID           = 'E1R109GF2KN71U'
        AWS_CLOUDFRONT_URL     = 'd1bctqdoo5thax.cloudfront.net'

        BUILD_START = "${System.currentTimeMillis()}"

    }

    stages {

        stage('BUILD') {

            stages {
/*                 stage('Install Dependencies') {
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
                } */

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
                                --report-path gitleaks-report.json
                        '''
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'gitleaks-report.json'
                        }
                        script {

                            def report = readJSON file: 'gitleaks-report.json'

                            def totalFindings = report.size()

                            writeFile(
                                file: 'gitleaks.prom',
                                text: "gitleaks_findings_total ${totalFindings}\n"
                            )

                            sh '''
                            curl --data-binary @gitleaks.prom \
                            http://192.168.1.194:9091/metrics/job/gitleaks
                            '''
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
                        sh '''
                            curl -u $SONAR_TOKEN: \
                            "https://sonarcloud.io/api/measures/component?component=learn-jenkins-app&metricKeys=coverage,bugs,vulnerabilities" \
                            -o sonar.json

                            BUGS=$(jq -r '.component.measures[] | select(.metric=="bugs").value' sonar.json)

                            VULNS=$(jq -r '.component.measures[] | select(.metric=="vulnerabilities").value' sonar.json)

                            cat <<EOF > sonar.prom
                                    sonar_bugs $BUGS
                                    sonar_vulnerabilities $VULNS
                                    EOF

                            curl --data-binary @sonar.prom \
                            http://192.168.1.194:9091/metrics/job/sonar
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
                        sh '''
                            TOTAL=$(jq '.results | length' semgrep-report.json)

                            echo "semgrep_findings_total $TOTAL" > semgrep.prom

                            curl --data-binary @semgrep.prom \
                            http://192.168.1.194:9091/metrics/job/semgrep
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
                        sh '''
                            CRITICAL=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' trivy-report.json)

                            HIGH=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="HIGH")] | length' trivy-report.json)

                            cat <<EOF > trivy.prom
                            trivy_critical $CRITICAL
                            trivy_high $HIGH
                            EOF

                            curl --data-binary @trivy.prom \
                            http://192.168.1.194:9091/metrics/job/trivy
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
                            npm run build

                            npx serve -s build -l 3000 &
                            SERVER_PID=$!

                            sleep 20

                            curl http://localhost:3000

                            npx playwright test 

                            kill $SERVER_PID

                        '''
                        sh '''
                            TOTAL=$(find test-results -name "*.xml" | wc -l)

                            echo "playwright_tests_total $TOTAL" > playwright.prom

                            curl --data-binary @playwright.prom \
                            http://192.168.1.194:9091/metrics/job/playwright
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
                        sh '''
                            COVERAGE=$(jq '.total.lines.pct' coverage/coverage-summary.json)

                            echo "coverage_percent $COVERAGE" > coverage.prom

                            curl --data-binary @coverage.prom \
                            http://192.168.1.194:9091/metrics/job/coverage
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
                            export REACT_APP_VERSION=${APP_VERSION}
                            npm run build                            
                        ''' //tar -czf build-${APP_VERSION}.tar.gz build
                        
                    }
                    post {
                        success {
                             /*archiveArtifacts(
                                artifacts: '*.tar.gz',
                                fingerprint: true
                            ) */

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
                                /* aws s3 cp \
                                build-${APP_VERSION}.tar.gz \
                                s3://chrrodri-build-artifacts/build-${APP_VERSION}.tar.gz */
                        }
                    }
                } 
            }
        }
    
         stage('DEPLOY') {
            stages {
                stage('Deploy') {
                    when {
                        branch 'main'
                    }
                    agent {
                        docker {
                            image "${K8S_IMAGE}"
                            args '--entrypoint=""'
                            reuseNode true
                        }
                    }
                    steps {
                        sh 'echo "Running Deploy Stage"'
                        //sh 'kubectl apply -f deployment.yaml'
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
            script {
                def duration = System.currentTimeMillis() - BUILD_START.toLong()

                sh """
                echo "pipeline_duration_ms ${duration}" > pipeline.prom

                curl --data-binary @pipeline.prom \
                http://192.168.1.194:9091/metrics/job/pipeline
                """
            }
            cleanWs()
        } 
    }    
}