pipeline {
    agent any

    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    // Define Docker Image name
                    def dockerImage = docker.build('npm-sample', '-f instDockerfile .')
                }
            }
        }

    }
}
