// Jenkins 파이프라인에서 kubernetes agent가 정상적으로 동작하는지 테스트하는 groovy 파일 예시
pipeline {
    agent {
        kubernetes {
            defaultContainer 'jnlp'
        }
    }
    stages {
        stage('Kubernetes Agent Test') {
            steps {
                container('jnlp') {
                    sh 'echo "Hello from Kubernetes agent!"'
                    sh 'uname -a'
                    sh 'kubectl version --client=true'
                }
            }
        }
    }
}
